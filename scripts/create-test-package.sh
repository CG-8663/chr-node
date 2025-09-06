#!/bin/bash

# Create a test package for Termux installation testing
# This creates a self-contained package for private repository testing

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Creating chr-node Test Package${NC}"
echo "================================="
echo ""

# Check if we're in the right directory
if [ ! -f "scripts/termux-one-click-install.sh" ]; then
    echo "❌ Please run this script from the chr-node root directory"
    exit 1
fi

# Create test package directory
TEST_DIR="chr-node-test-package"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

echo "📁 Creating test package in: $TEST_DIR"
echo ""

# Copy installation script
echo "📋 Copying installation script..."
cp scripts/termux-one-click-install.sh "$TEST_DIR/"

# Create a simple web server for local testing
echo "🌐 Creating local web server..."
cat > "$TEST_DIR/simple-server.py" << 'EOF'
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
EOF

chmod +x "$TEST_DIR/simple-server.py"

# Create a README for the test package
echo "📝 Creating test instructions..."
cat > "$TEST_DIR/README.md" << EOF
# chr-node Test Package

This package contains everything needed to test chr-node installation while the repository is private.

## 🧪 Testing Methods

### Method 1: Direct Script Testing

1. Copy the script to your Android device:
   \`\`\`bash
   scp termux-one-click-install.sh android-device:/sdcard/
   \`\`\`

2. In Termux on Android:
   \`\`\`bash
   cp /sdcard/termux-one-click-install.sh .
   chmod +x termux-one-click-install.sh
   ./termux-one-click-install.sh
   \`\`\`

### Method 2: Local Web Server

1. Start the local server (requires Python 3):
   \`\`\`bash
   python3 simple-server.py
   \`\`\`

2. Find your local IP address:
   \`\`\`bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   \`\`\`

3. In Termux on Android (connected to same WiFi):
   \`\`\`bash
   curl -L http://YOUR_IP:8080/install | bash
   \`\`\`

### Method 3: Web Interface Testing

If you want to test the full web interface:

1. Go back to main chr-node directory
2. Start the web server:
   \`\`\`bash
   cd web-deployment
   npm install
   npm start
   \`\`\`
3. Open http://localhost:3333 in browser
4. Test QR code and copy command functionality

## 📋 Files Included

- \`termux-one-click-install.sh\` - The main installation script
- \`simple-server.py\` - Local web server for testing
- \`README.md\` - This instruction file

## 🎯 What to Test

1. **Script Execution**: Does the installation script run without errors?
2. **Dependency Installation**: Are all packages installed correctly?
3. **Service Creation**: Does chr-node-service command work?
4. **Web Interface**: Can you access http://localhost:3000?
5. **Termux APIs**: Do the API tests pass?
6. **Configuration**: Are all config files generated properly?

## 🐛 Troubleshooting

- **Permission Denied**: Make sure script is executable (\`chmod +x\`)
- **Network Issues**: Ensure Android and computer are on same WiFi
- **Port Conflicts**: Change PORT in simple-server.py if 8080 is in use
- **Installation Fails**: Check Termux has sufficient storage space

## ✅ Success Criteria

After installation, you should have:
- ✅ chr-node service running
- ✅ Web interface accessible at http://localhost:3000
- ✅ Service management commands available
- ✅ Termux API integration working
- ✅ Configuration files generated

## 🚀 Next Steps

Once testing is complete and everything works:
1. Make repository public
2. Create official release
3. Update documentation
4. Deploy to production

Happy testing! 🧪
EOF

# Create a quick test script
echo "🧪 Creating quick test script..."
cat > "$TEST_DIR/quick-test.sh" << 'EOF'
#!/bin/bash

echo "🧪 Quick Test of chr-node Installation"
echo "====================================="

# Test script syntax
if bash -n termux-one-click-install.sh; then
    echo "✅ Installation script syntax is valid"
else
    echo "❌ Installation script has syntax errors"
    exit 1
fi

# Show script size
LINES=$(wc -l < termux-one-click-install.sh)
echo "📊 Script size: $LINES lines"

# Test dependencies
echo ""
echo "🔍 Testing dependencies..."

if command -v python3 &> /dev/null; then
    echo "✅ Python 3 available for local server"
else
    echo "❌ Python 3 not found - install for local server testing"
fi

if command -v curl &> /dev/null; then
    echo "✅ curl available"
else
    echo "❌ curl not found"
fi

echo ""
echo "📋 Ready for testing!"
echo ""
echo "Methods available:"
echo "1. Direct: Copy script to Android and run"
echo "2. Server: python3 simple-server.py"
echo "3. Web UI: Go to ../web-deployment && npm start"
echo ""
echo "See README.md for detailed instructions."
EOF

chmod +x "$TEST_DIR/quick-test.sh"

# Create package info
echo "📊 Creating package info..."
cat > "$TEST_DIR/PACKAGE-INFO.txt" << EOF
chr-node Test Package
====================

Created: $(date)
Directory: $(pwd)
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "Not in git repository")
Git Branch: $(git branch --show-current 2>/dev/null || echo "Unknown")

Files Included:
- termux-one-click-install.sh ($(wc -l < scripts/termux-one-click-install.sh) lines)
- simple-server.py (Local web server)
- README.md (Testing instructions)
- quick-test.sh (Quick validation)
- PACKAGE-INFO.txt (This file)

Purpose:
This package enables testing chr-node installation while the repository
is private. Use local file copying or local web server for testing.

When ready for public release:
1. Make repository public: gh repo edit --visibility public
2. Create release: gh release create v1.0.0
3. Users install with: curl -L https://raw.githubusercontent.com/USER/REPO/main/scripts/termux-one-click-install.sh | bash
EOF

echo ""
echo -e "${GREEN}✅ Test package created successfully!${NC}"
echo ""
echo "📦 Package location: $TEST_DIR"
echo "📋 Package contents:"
ls -la "$TEST_DIR"

echo ""
echo -e "${YELLOW}🧪 Quick Start Testing:${NC}"
echo ""
echo "1. Run quick test:"
echo "   cd $TEST_DIR && ./quick-test.sh"
echo ""
echo "2. Start local server:"
echo "   cd $TEST_DIR && python3 simple-server.py"
echo ""
echo "3. Copy to Android device:"
echo "   scp $TEST_DIR/termux-one-click-install.sh android-device:/sdcard/"
echo ""
echo "4. Read full instructions:"
echo "   cat $TEST_DIR/README.md"

echo ""
echo -e "${BLUE}📱 For Termux testing:${NC}"
echo "Connect Android to same WiFi, then use local server method"
echo "or copy script directly to device and run."

echo ""
echo -e "${GREEN}🎯 This approach lets you test thoroughly before going public!${NC}"