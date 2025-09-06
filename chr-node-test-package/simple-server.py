#!/usr/bin/env python3
"""
Simple HTTP server for testing chr-node installation locally.
Serves the installation script for Termux testing.
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8080
SCRIPT_FILE = "termux-one-click-install.sh"

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/install':
            # Serve the installation script
            if os.path.exists(SCRIPT_FILE):
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain')
                self.send_header('Content-Disposition', 'attachment; filename="chr-node-install.sh"')
                self.end_headers()
                
                with open(SCRIPT_FILE, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self.send_error(404, "Installation script not found")
                
        elif self.path == '/':
            # Serve a simple landing page
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            
            html = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <title>chr-node Local Test Server</title>
                <style>
                    body {{ font-family: Arial, sans-serif; text-align: center; padding: 50px; }}
                    .container {{ max-width: 600px; margin: 0 auto; }}
                    .button {{ background: #007bff; color: white; padding: 10px 20px; 
                             text-decoration: none; border-radius: 5px; margin: 10px; 
                             display: inline-block; }}
                    code {{ background: #f4f4f4; padding: 20px; border-radius: 5px; 
                           display: block; margin: 20px 0; font-family: monospace; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🌐 chr-node Local Test Server</h1>
                    <h2>Testing Installation Script</h2>
                    
                    <p>This server is running on your local machine for testing chr-node installation.</p>
                    
                    <a href="/install" class="button">📱 Download Install Script</a>
                    
                    <h3>📋 Installation Command for Termux:</h3>
                    <code>curl -L http://YOUR_IP:8080/install | bash</code>
                    
                    <h3>🔍 Find Your IP Address:</h3>
                    <p>Run this on your Mac/PC: <code>ifconfig | grep "inet " | grep -v 127.0.0.1</code></p>
                    
                    <h3>📱 In Termux on Android:</h3>
                    <ol>
                        <li>Connect Android to same WiFi network</li>
                        <li>Replace YOUR_IP with your actual IP address</li>
                        <li>Run the curl command above</li>
                    </ol>
                    
                    <p><small>Server running on port {PORT}</small></p>
                </div>
            </body>
            </html>
            """
            
            self.wfile.write(html.encode('utf-8'))
        else:
            super().do_GET()

def main():
    os.chdir(os.path.dirname(__file__))
    
    print(f"🌐 Starting chr-node test server on port {PORT}...")
    print(f"📄 Serving installation script: {SCRIPT_FILE}")
    print("")
    
    # Get local IP
    import socket
    try:
        # Connect to a remote address to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        
        print(f"🏠 Local server: http://localhost:{PORT}")
        print(f"📱 Mobile access: http://{local_ip}:{PORT}")
        print(f"📋 Install command: curl -L http://{local_ip}:{PORT}/install | bash")
        print("")
        print("Press Ctrl+C to stop the server")
        print("=" * 60)
        
    except Exception:
        local_ip = "YOUR_IP"
        print(f"🏠 Local server: http://localhost:{PORT}")
        print(f"📱 Mobile access: http://YOUR_IP:{PORT}")
        print("(Replace YOUR_IP with your actual IP address)")
    
    try:
        with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped")

if __name__ == "__main__":
    main()
