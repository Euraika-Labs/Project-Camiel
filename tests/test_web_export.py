"""Check the actual local hosting contract used by the web export instructions."""
import argparse
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.request import urlopen

from scripts.tools.serve_web import WebHandler, export_directory


class WebExportTests(unittest.TestCase):
    def test_incomplete_export_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(argparse.ArgumentTypeError, "index.wasm"):
                export_directory(directory)

    def test_export_is_served_with_wasm_mime_and_no_stale_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, data in {"index.html": b"Camiel", "index.js": b"// engine",
                               "index.wasm": b"\x00asm", "index.pck": b"pack"}.items():
                (root / name).write_bytes(data)
            self.assertEqual(export_directory(directory), root.resolve())
            server = ThreadingHTTPServer(("127.0.0.1", 0), partial(WebHandler, directory=directory))
            worker = threading.Thread(target=server.serve_forever, daemon=True)
            worker.start()
            try:
                base = f"http://127.0.0.1:{server.server_port}"
                for path, mime in (("index.wasm", "application/wasm"),
                                   ("index.js", "application/javascript"),
                                   ("index.pck", "application/octet-stream")):
                    with self.subTest(path=path), urlopen(f"{base}/{path}") as response:
                        self.assertEqual(response.headers.get_content_type(), mime)
                        self.assertEqual(response.headers["Cache-Control"], "no-store")
                        self.assertEqual(response.read(), (root / path).read_bytes())
            finally:
                server.shutdown()
                server.server_close()
                worker.join()


if __name__ == "__main__":
    unittest.main()
