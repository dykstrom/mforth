"""The lab pages' web server.

    python3 tools/serve.py <repository root>

Serves the repository root on port 8000, because the pages load the
highlighter and the x86 grammar from slides/. The pages themselves are in
lab/, so a request for / is sent on to /lab/. Codespaces opens the forwarded
port at /, and without this the attendee lands on a directory listing.
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


handler = functools.partial(Handler, directory=sys.argv[1])
http.server.ThreadingHTTPServer(("", 8000), handler).serve_forever()
