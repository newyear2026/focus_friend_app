#!/usr/bin/env python3
"""Local static previews with byte ranges for seeking Flutter capture videos."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re


class PreviewHandler(SimpleHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def end_headers(self):
        self.send_header('Accept-Ranges', 'bytes')
        super().end_headers()

    def send_head(self):
        self.byte_range = None
        path = Path(self.translate_path(self.path))
        header = self.headers.get('Range', '')
        if not header or not path.is_file():
            return super().send_head()
        match = re.fullmatch(r'bytes=(\d*)-(\d*)', header)
        length = path.stat().st_size
        if not match or not length:
            self.send_error(416)
            return None
        left, right = match.groups()
        start = int(left) if left else max(0, length - int(right or length))
        end = min(int(right), length - 1) if left and right else length - 1
        if start > end or start >= length:
            self.send_error(416)
            return None
        source = path.open('rb')
        source.seek(start)
        self.byte_range = (start, end)
        self.send_response(206)
        self.send_header('Content-Type', self.guess_type(str(path)))
        self.send_header('Content-Length', str(end - start + 1))
        self.send_header('Content-Range', f'bytes {start}-{end}/{length}')
        self.end_headers()
        return source

    def copyfile(self, source, outputfile):
        if self.byte_range is None:
            return super().copyfile(source, outputfile)
        remaining = self.byte_range[1] - self.byte_range[0] + 1
        while remaining:
            chunk = source.read(min(65536, remaining))
            if not chunk:
                break
            outputfile.write(chunk)
            remaining -= len(chunk)


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1] / 'docs/design'
    ThreadingHTTPServer(('127.0.0.1', 8112),
                        partial(PreviewHandler, directory=str(root))).serve_forever()
