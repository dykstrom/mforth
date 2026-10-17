"""The lab pages' web server.

    python3 tools/serve.py <repository root>

Serves the repository root on port 8000, because the pages load the
highlighter and the x86 grammar from slides/. The pages themselves are in
lab/, so a request for / is sent on to /lab/. Codespaces opens the forwarded
port at /, and without this the attendee lands on a directory listing.

Every response says Cache-Control: no-cache. Without it the browser decides
for itself how long a file stays fresh, and keeps showing an old
exercises.json, or an old page, after the file has changed. With it the
browser asks every time, and gets a short "not modified" when nothing has.
"""

import functools
import http.server
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(302)
            self.send_header("Location", "/lab/")
            self.end_headers()
            return
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


handler = functools.partial(Handler, directory=sys.argv[1])
http.server.ThreadingHTTPServer(("", 8000), handler).serve_forever()
