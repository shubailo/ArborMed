import http.server
import socketserver
import os

PORT = 5000
DIRECTORY = "apps/student_app/build/web"

class WasmHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Enable Cross-Origin Isolation (Needed for Drift Wasm if using SharedArrayBuffer)
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

# Add WASM MIME type explicitly
WasmHandler.extensions_map.update({
    '.wasm': 'application/wasm',
})

os.makedirs(DIRECTORY, exist_ok=True)

with socketserver.TCPServer(("", PORT), WasmHandler) as httpd:
    print(f"🚀 Serving ArborMed Web at http://localhost:{PORT}")
    print(f"📁 Directory: {DIRECTORY}")
    print("✨ WASM MIME types and CORS isolation enabled.")
    httpd.serve_forever()
