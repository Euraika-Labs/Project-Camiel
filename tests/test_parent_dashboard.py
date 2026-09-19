"""Real HTTP contract/security tests using synthetic progress only."""
import copy
import http.client
import json
from pathlib import Path
import tempfile
import threading
import unittest

from dashboard.server import DashboardServer, MAX_UPLOAD, MAX_ENTRIES, InvalidProgress, parse_progress


def entry(stars=3, seconds=1.25, stamp='2026-06-05T14:32:00'):
    return {'lesson_id': 'lesson_1', 'stars': stars, 'time_seconds': seconds, 'completed_at': stamp}


def multipart(raw, filename='progress.json'):
    return (b'--camiel-test\r\nContent-Disposition: form-data; name="file"; filename="' + filename.encode()
            + b'"\r\nContent-Type: application/json\r\n\r\n' + raw + b'\r\n--camiel-test--\r\n')


class DashboardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = DashboardServer(0)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def setUp(self):
        self.server.progress = {'version': 1, 'entries': []}

    def request(self, method, path, body=None, headers=None):
        connection = http.client.HTTPConnection('127.0.0.1', self.server.server_port, timeout=3)
        try:
            connection.request(method, path, body=body, headers=headers or {})
            response = connection.getresponse()
            raw = response.read()
            return response.status, dict(response.getheaders()), raw
        finally:
            connection.close()

    def upload(self, data, filename='progress.json', headers=None):
        raw = data if isinstance(data, bytes) else json.dumps(data).encode()
        return self.request('POST', '/api/progress/import', multipart(raw, filename),
                            {'Content-Type': 'multipart/form-data; boundary=camiel-test', **(headers or {})})

    def test_empty_and_local_binding(self):
        self.assertEqual(self.server.server_address[0], '127.0.0.1')
        status, headers, raw = self.request('GET', '/api/summary')
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(raw), {'total_lessons_completed': 0, 'total_stars': 0,
                         'total_time_seconds': 0, 'star_rating_breakdown': {'1_star': 0, '2_star': 0, '3_star': 0}, 'last_session': None})
        self.assertEqual(headers['Cache-Control'], 'no-store')
        self.assertNotIn('Access-Control-Allow-Origin', headers)

    def test_append_history_summary_and_reimport(self):
        data = {'version': 1, 'entries': [entry(2, 2.5, '2026-07-01T08:00:00'), entry(3), entry(1, 0)]}
        self.assertEqual(self.upload(data)[0], 200)
        self.assertEqual(self.upload(data)[0], 200)
        self.assertEqual(json.loads(self.request('GET', '/api/progress')[2]), data)
        self.assertEqual(json.loads(self.request('GET', '/api/summary')[2]), {
            'total_lessons_completed': 3, 'total_stars': 6, 'total_time_seconds': 3.75,
            'star_rating_breakdown': {'1_star': 1, '2_star': 1, '3_star': 1}, 'last_session': '2026-07-01T08:00:00'})
        self.upload({'version': 1, 'entries': []})
        self.assertEqual(json.loads(self.request('GET', '/api/progress')[2])['entries'], [])

    def test_invalid_upload_preserves_snapshot(self):
        good = {'version': 1, 'entries': [entry()]}
        self.upload(good)
        invalid = [b'', b'{}', b'null', b'\xff', b'{', b'{"version":1,"version":1,"entries":[]}',
                   b'[' * 1500, {'lessons': []}, {'version': True, 'entries': []},
                   {'version': 2, 'entries': []}, {'version': 1, 'entries': [None]}]
        for field, value in [('stars', True), ('stars', 0), ('stars', 4), ('stars', 2.5),
                             ('time_seconds', -1), ('time_seconds', float('nan')),
                             ('time_seconds', float('inf')), ('time_seconds', True),
                             ('time_seconds', 31536001), ('lesson_id', '../save'),
                             ('lesson_id', '<script>'), ('lesson_id', ''),
                             ('completed_at', '2026-02-30T00:00:00'),
                             ('completed_at', '2026-01-01T00:00:00Z')]:
            data = copy.deepcopy(good)
            data['entries'][0][field] = value
            invalid.append(data)
        for data in invalid:
            with self.subTest(data=str(data)[:120]):
                self.assertEqual(self.upload(data)[0], 400)
                self.assertEqual(json.loads(self.request('GET', '/api/progress')[2]), good)

    def test_limits_and_multipart(self):
        self.assertEqual(self.request('POST', '/api/progress/import', b'', {'Content-Length': str(MAX_UPLOAD + 1)})[0], 413)
        self.assertEqual(self.request('POST', '/api/progress/import', b'{}', {'Content-Type': 'application/json'})[0], 400)
        self.assertEqual(self.request('POST', '/api/progress/import', b'', {'Transfer-Encoding': 'chunked'})[0], 411)
        self.assertEqual(self.request('POST', '/api/progress/import', b'', {'Content-Length': '-1'})[0], 411)
        body = multipart(b'{}').replace(b'name="file"', b'name="wrong"')
        self.assertEqual(self.request('POST', '/api/progress/import', body, {'Content-Type': 'multipart/form-data; boundary=camiel-test'})[0], 400)
        body = multipart(b'{}').replace(b'--camiel-test--\r\n', b'')
        self.assertEqual(self.request('POST', '/api/progress/import', body, {'Content-Type': 'multipart/form-data; boundary=camiel-test'})[0], 400)
        with self.assertRaises(InvalidProgress):
            parse_progress(json.dumps({'version': 1, 'entries': [entry()] * (MAX_ENTRIES + 1)}).encode())

    def test_multiple_parts_and_entry_boundary(self):
        body = multipart(b'{}').replace(b'--camiel-test--\r\n', multipart(b'{}'))
        self.assertEqual(self.request('POST', '/api/progress/import', body,
            {'Content-Type': 'multipart/form-data; boundary=camiel-test'})[0], 400)
        data = {'version': 1, 'entries': [entry()] * MAX_ENTRIES}
        self.assertEqual(self.upload(data)[0], 200)
        self.assertEqual(json.loads(self.request('GET', '/api/summary')[2])['total_lessons_completed'], MAX_ENTRIES)
        raw = json.dumps(data).encode()
        # Exercise the exact accepted HTTP-body boundary with a real full upload.
        padding = MAX_UPLOAD - len(multipart(raw))
        self.assertGreater(padding, 0)
        self.assertEqual(self.upload(raw + b' ' * padding)[0], 200)
        # Read the early rejection before pushing an already-rejected body.
        # Sending that body races TCP close/reset and obscures the HTTP result.
        status, _, response = self.request('POST', '/api/progress/import', headers={
            'Content-Type': 'multipart/form-data; boundary=camiel-test',
            'Content-Length': str(MAX_UPLOAD + 1),
        })
        self.assertEqual(status, 413)
        self.assertIn('te groot', json.loads(response)['error'])
        self.assertEqual(json.loads(self.request('GET', '/api/progress')[2]), data)

    def test_origins_hosts_and_paths(self):
        for headers in [{'Host': 'evil.example'}, {'Origin': 'https://evil.example'},
                        {'Origin': 'null'}, {'Sec-Fetch-Site': 'cross-site'},
                        {'Sec-Fetch-Site': 'same-site'}]:
            self.assertEqual(self.request('GET', '/api/progress', headers=headers)[0], 403)
            self.assertEqual(self.upload({'version': 1, 'entries': []}, headers=headers)[0], 403)
        origin = f'http://127.0.0.1:{self.server.server_port}'
        self.assertEqual(self.upload({'version': 1, 'entries': []}, headers={'Origin': origin})[0], 200)
        for path in ['/../project.godot', '/%2e%2e/project.godot', '/server.py', '//etc/passwd']:
            self.assertEqual(self.request('GET', path)[0], 404)

    def test_filename_never_writes_game_save(self):
        with tempfile.TemporaryDirectory() as folder:
            save = Path(folder) / 'progress.json'
            save.write_bytes(b'original game save')
            for filename in [str(save), '../../progress.json']:
                self.assertEqual(self.upload({'version': 1, 'entries': [entry()]}, filename)[0], 200)
                self.assertEqual(save.read_bytes(), b'original game save')

    def test_assets_are_local_and_dutch(self):
        for path in ['/', '/app.js', '/style.css']:
            status, headers, raw = self.request('GET', path)
            self.assertEqual(status, 200)
            self.assertIn("connect-src 'self'", headers['Content-Security-Policy'])
            self.assertNotIn(b'https://', raw)
            self.assertNotIn(b'http://', raw)
        self.assertIn(b'lang="nl"', self.request('GET', '/')[2])


if __name__ == '__main__':
    unittest.main()
