"""Serve an extracted Camiel web export on loopback with explicit WASM MIME type."""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class WebHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "application/javascript",
        ".pck": "application/octet-stream",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def export_directory(value: str) -> Path:
    directory = Path(value).resolve()
    missing = [name for name in ("index.html", "index.js", "index.wasm", "index.pck")
               if not (directory / name).is_file()]
    if missing:
        raise argparse.ArgumentTypeError("Incomplete web export: missing " + ", ".join(missing))
    return directory


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=export_directory, help="Extracted web export directory")
    parser.add_argument("--port", type=int, default=8060)
    args = parser.parse_args()
    handler = partial(WebHandler, directory=str(args.directory))
    with ThreadingHTTPServer(("127.0.0.1", args.port), handler) as server:
        print(f"Camiel: http://127.0.0.1:{server.server_port}/index.html", flush=True)
        print("Keep this origin (including port) to retain browser progress. Ctrl+C stops the server.", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
