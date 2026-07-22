#!/usr/bin/env python3
"""Serve Flutter web build with no-cache headers (avoids white-screen stale loads)."""

from __future__ import annotations

import functools
import http.server
import os
import sys


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **getattr(http.server.SimpleHTTPRequestHandler, "extensions_map", {}),
        ".js": "application/javascript",
        ".mjs": "application/javascript",
        ".json": "application/json",
        ".wasm": "application/wasm",
        ".css": "text/css",
        ".html": "text/html",
        ".svg": "image/svg+xml",
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
        ".woff": "font/woff",
        ".woff2": "font/woff2",
    }

    def end_headers(self) -> None:
        path = self.path.split("?", 1)[0].lower()
        if path.endswith((".html", ".js", ".mjs", ".json")) or path in ("/", ""):
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
        else:
            self.send_header("Cache-Control", "public, max-age=3600")
        super().end_headers()

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        sys.stderr.write("%s - %s\n" % (self.address_string(), format % args))


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: serve_web_nocache.py <web_dir> <port>", file=sys.stderr)
        return 2
    web_dir = os.path.abspath(sys.argv[1])
    port = int(sys.argv[2])
    if not os.path.isdir(web_dir):
        print(f"Missing web dir: {web_dir}", file=sys.stderr)
        return 1
    os.chdir(web_dir)
    handler = functools.partial(NoCacheHandler, directory=web_dir)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    print(f"Serving {web_dir} on http://127.0.0.1:{port}/ (no-cache HTML/JS)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
