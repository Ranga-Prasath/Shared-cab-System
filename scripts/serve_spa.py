import http.server
import os
import sys


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def do_GET(self):
        path = self.translate_path(self.path)
        if self.path != "/" and not os.path.exists(path):
            self.path = "/index.html"
        return super().do_GET()


def main():
    directory = sys.argv[1] if len(sys.argv) > 1 else "."
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 5174
    with http.server.ThreadingHTTPServer(
        ("127.0.0.1", port),
        lambda *args, **kwargs: SpaHandler(*args, directory=directory, **kwargs),
    ) as httpd:
        httpd.serve_forever()


if __name__ == "__main__":
    main()
