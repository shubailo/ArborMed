import http.server
import socketserver
import os
import mimetypes

# Minimal Python server with correct MIME types for Flutter Web
PORT = 8080
DIRECTORY = "build/web"

class FlutterWebHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Add COOP and COEP headers for modern Flutter Web rendering (WASM/CanvasKit)
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def do_GET(self):
        # Fallback to index.html for SPAs (Flutter Web)
        path = self.translate_path(self.path)
        if not os.path.exists(path) or os.path.isdir(path):
            self.path = "/index.html"
        return super().do_GET()

# Ensure WASM MIME type is registered
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('text/javascript', '.js')
mimetypes.add_type('text/html', '.html')

if __name__ == "__main__":
    if not os.path.exists(DIRECTORY):
        print(f"Error: Directory {DIRECTORY} not found. Run 'flutter build web' first.")
        # Create dummy structure if building manually for testing
        # os.makedirs(DIRECTORY, exist_ok=True)
    
    with socketserver.TCPServer(("", PORT), FlutterWebHandler) as httpd:
        print(f"Serving Flutter Web at http://localhost:{PORT}")
        print(f"MIME types: .wasm -> {mimetypes.guess_type('test.wasm')[0]}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
