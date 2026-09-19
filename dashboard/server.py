"""Offline parent dashboard. No game save is opened or written by this module."""

import argparse
from datetime import datetime
from email import policy
from email.parser import BytesParser
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import math
from pathlib import Path
import re
import socket

MAX_UPLOAD = 2 * 1024 * 1024
MAX_ENTRIES = 10000
ASSETS = {
    '/': ('index.html', 'text/html; charset=utf-8'),
    '/app.js': ('app.js', 'text/javascript; charset=utf-8'),
    '/style.css': ('style.css', 'text/css; charset=utf-8'),
}


class InvalidProgress(ValueError):
    pass


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise InvalidProgress('Dubbele JSON-velden zijn niet toegestaan.')
        result[key] = value
    return result


def parse_progress(raw):
    """Validate the exact version 1 append-log schema produced by Godot."""
    if len(raw) > MAX_UPLOAD:
        raise InvalidProgress('Bestand is te groot (maximaal 2 MiB).')
    try:
        data = json.loads(raw.decode('utf-8-sig'), object_pairs_hook=_unique_object)
    except (ValueError, UnicodeError, RecursionError) as exc:
        raise InvalidProgress('Ongeldig JSON-bestand.') from exc
    if (not isinstance(data, dict) or set(data) != {'version', 'entries'}
            or type(data['version']) is not int or data['version'] != 1
            or not isinstance(data['entries'], list)):
        raise InvalidProgress('Verwacht versie 1 met een entries-lijst.')
    if len(data['entries']) > MAX_ENTRIES:
        raise InvalidProgress('Maximaal 10.000 lesafrondingen toegestaan.')
    for entry in data['entries']:
        if not isinstance(entry, dict) or set(entry) != {
                'lesson_id', 'stars', 'time_seconds', 'completed_at'}:
            raise InvalidProgress('Een lesafronding heeft ongeldige velden.')
        if not isinstance(entry['lesson_id'], str) or not re.fullmatch(
                r'[A-Za-z0-9_-]{1,100}', entry['lesson_id']):
            raise InvalidProgress('Ongeldige lescode.')
        if type(entry['stars']) is not int or not 1 <= entry['stars'] <= 3:
            raise InvalidProgress('Sterren moeten een geheel getal van 1 tot 3 zijn.')
        duration = entry['time_seconds']
        if (type(duration) not in (int, float) or not 0 <= duration <= 31536000
                or not math.isfinite(duration)):
            raise InvalidProgress('Speeltijd moet tussen 0 en 31.536.000 seconden liggen.')
        stamp = entry['completed_at']
        if not isinstance(stamp, str) or not re.fullmatch(
                r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}', stamp):
            raise InvalidProgress('Datum moet JJJJ-MM-DDTuu:mm:ss zijn.')
        try:
            datetime.fromisoformat(stamp)
        except ValueError as exc:
            raise InvalidProgress('Ongeldige kalenderdatum.') from exc
    return data


def summarize(data):
    entries = data['entries']
    return {
        'total_lessons_completed': len(entries),
        'total_stars': sum(e['stars'] for e in entries),
        'total_time_seconds': math.fsum(e['time_seconds'] for e in entries),
        'star_rating_breakdown': {
            f'{n}_star': sum(e['stars'] == n for e in entries) for n in (1, 2, 3)
        },
        'last_session': max((e['completed_at'] for e in entries), default=None),
    }


def parse_upload(content_type, body):
    if '\r' in content_type or '\n' in content_type:
        raise InvalidProgress('Ongeldig uploadformaat.')
    message = BytesParser(policy=policy.default).parsebytes(
        b'Content-Type: ' + content_type.encode('ascii') + b'\r\nMIME-Version: 1.0\r\n\r\n' + body)
    if message.get_content_type() != 'multipart/form-data' or not message.is_multipart():
        raise InvalidProgress('Gebruik multipart/form-data met één file-veld.')
    parts = list(message.iter_parts())
    if (message.defects or len(parts) != 1 or parts[0].is_multipart()
            or parts[0].defects
            or parts[0].get_content_disposition() != 'form-data'
            or parts[0].get_param('name', header='content-disposition') != 'file'
            or parts[0].get_filename() is None
            or parts[0].get('Content-Transfer-Encoding') is not None):
        raise InvalidProgress('Upload precies één bestand in het file-veld.')
    # Filename is metadata only. It is never resolved or written to disk.
    return parse_progress(parts[0].get_payload(decode=True))


class DashboardServer(HTTPServer):
    """Single-threaded bounded requests; snapshot replacement is atomic."""

    def __init__(self, port=8765):
        self.progress = {'version': 1, 'entries': []}
        super().__init__(('127.0.0.1', port), Handler)

    def get_request(self):
        sock, address = super().get_request()
        sock.settimeout(5)
        return sock, address


class Handler(BaseHTTPRequestHandler):
    server_version = 'CamielDashboard'

    def log_message(self, format, *args):
        pass  # No child data, upload filenames or request URLs in logs.

    def respond(self, status, data, content_type='application/json; charset=utf-8'):
        body = json.dumps(data, ensure_ascii=False, allow_nan=False).encode() if isinstance(data, dict) else data
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'no-referrer')
        self.send_header('Content-Security-Policy', "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'")
        self.send_header('Connection', 'close')
        self.end_headers()
        self.close_connection = True
        self.wfile.write(body)

    def local_request(self):
        host = f'127.0.0.1:{self.server.server_port}'
        origins = self.headers.get_all('Origin', [])
        if (self.headers.get_all('Host', []) != [host]
                or origins not in ([], ['http://' + host])
                or self.headers.get('Sec-Fetch-Site', 'none') not in ('none', 'same-origin')):
            self.respond(403, {'error': 'Alleen toegang vanaf dit lokale dashboard is toegestaan.'})
            return False
        return True

    def do_GET(self):
        if not self.local_request():
            return
        if self.path == '/api/progress':
            self.respond(200, self.server.progress)
        elif self.path == '/api/summary':
            self.respond(200, summarize(self.server.progress))
        elif self.path in ASSETS:
            name, content_type = ASSETS[self.path]
            self.respond(200, Path(__file__).with_name(name).read_bytes(), content_type)
        else:
            self.respond(404, {'error': 'Pagina niet gevonden.'})

    def do_POST(self):
        if not self.local_request():
            return
        if self.path != '/api/progress/import':
            self.respond(404, {'error': 'Pagina niet gevonden.'})
            return
        lengths = self.headers.get_all('Content-Length', [])
        if self.headers.get('Transfer-Encoding') or len(lengths) != 1 or not re.fullmatch(r'[0-9]{1,10}', lengths[0]):
            self.respond(411, {'error': 'Eén geldige Content-Length is verplicht.'})
            return
        length = int(lengths[0])
        if length > MAX_UPLOAD:
            self.respond(413, {'error': 'Upload is te groot (maximaal 2 MiB inclusief formulier).'} )
            return
        try:
            body = self.rfile.read(length)
            if len(body) != length:
                raise InvalidProgress('Upload is onvolledig.')
            data = parse_upload(self.headers.get('Content-Type', ''), body)
        except (InvalidProgress, UnicodeError, ValueError, RecursionError) as exc:
            self.respond(400, {'error': str(exc)})
            return
        except (TimeoutError, socket.timeout):
            self.respond(408, {'error': 'Upload duurde te lang.'})
            return
        self.server.progress = data
        self.respond(200, data)


def main():
    parser = argparse.ArgumentParser(description='Lokaal Camiel-ouderdashboard')
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    with DashboardServer(args.port) as server:
        print(f'Ouderdashboard: http://127.0.0.1:{server.server_port} — stoppen met Ctrl+C', flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
