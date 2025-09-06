# chr-node First Termux Node Setup Guide

## Step-by-Step Manual Setup (First Node)

### Prerequisites
1. **Android Device** with Termux installed
2. **Termux:API** installed from F-Droid
3. **Internet connection** (WiFi or mobile data)
4. **Basic terminal knowledge**

### Step 1: Install Termux and Termux:API

1. **Download Termux from F-Droid** (recommended)
   ```
   https://f-droid.org/packages/com.termux/
   ```

2. **Download Termux:API**
   ```
   https://f-droid.org/packages/com.termux.api/
   ```

3. **Open Termux** and grant necessary permissions when prompted

### Step 2: Basic Termux Setup

```bash
# Update package repositories
pkg update && pkg upgrade -y

# Install essential tools
pkg install curl wget git nano -y

# Set storage permissions
termux-setup-storage
```

### Step 3: Download and Run chr-node Installation

```bash
# Download the installation script directly from GitHub
curl -L -o chr-node-install.sh "https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh"

# Make it executable
chmod +x chr-node-install.sh

# Run the installation (this will take 5-10 minutes)
./chr-node-install.sh
```

### Step 4: Initial Configuration

```bash
# The installation script will prompt for:
# 1. Node name (default: chr-node-android)
# 2. Tailscale setup (Y/n)
# 3. API keys (optional, can be added later)

# Follow the prompts and wait for installation to complete
```

### Step 5: Verify Installation

```bash
# Check chr-node service status
chr-node-service status

# Test web interface
curl http://localhost:3000/api/status

# Check Termux API integration
$HOME/.chr-node/bin/test-termux-api

# View your node ID and access info
cat $HOME/.chr-node/config/node-info.txt
```

### Step 6: Access Web Interface

1. **Find your device IP address:**
   ```bash
   # Get local IP
   ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "127.0.0.1"
   ```

2. **Open browser and navigate to:**
   ```
   http://[your-device-ip]:3000
   ```

3. **Connect your wallet and verify NFT ownership**

### Step 7: Setup Tailscale (for remote access)

```bash
# Install Tailscale
pkg install tailscale -y

# Start Tailscale daemon
sudo tailscaled &

# Authenticate (will show login URL)
sudo tailscale up

# Get your Tailscale IP
tailscale ip -4
```

---

## Automatic Provisioning System

### One-Click Installation Website

Create a simple webpage that users can click to automatically provision their chr-node:

#### Website Landing Page

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>chr-node - One-Click Install</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 600px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
        }
        .logo {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1rem;
        }
        .install-button {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 15px 40px;
            font-size: 1.2rem;
            border-radius: 50px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 10px;
            transition: transform 0.2s;
        }
        .install-button:hover {
            transform: translateY(-2px);
        }
        .steps {
            text-align: left;
            margin-top: 30px;
        }
        .step {
            margin: 15px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .requirements {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }
        .qr-code {
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌐</div>
        <h1>chr-node One-Click Install</h1>
        <p class="subtitle">Join the Chronara Network in under 5 minutes</p>
        
        <div class="requirements">
            <h3>📱 Requirements</h3>
            <ul>
                <li>Android 7.0+ with 1GB RAM</li>
                <li>Termux app installed</li>
                <li>Chronara Node Pass NFT</li>
                <li>Internet connection</li>
            </ul>
        </div>

        <div class="steps">
            <div class="step">
                <strong>Step 1:</strong> Install Termux from F-Droid
                <br><small>Download: <a href="https://f-droid.org/packages/com.termux/">F-Droid Termux</a></small>
            </div>
            
            <div class="step">
                <strong>Step 2:</strong> Click the install button below
                <br><small>This will copy the installation command to your clipboard</small>
            </div>
            
            <div class="step">
                <strong>Step 3:</strong> Paste and run in Termux
                <br><small>The installation will complete automatically</small>
            </div>
        </div>

        <a href="#" class="install-button" id="installBtn" onclick="copyInstallCommand()">
            📱 One-Click Install
        </a>
        
        <a href="#" class="install-button" onclick="showQR()">
            📲 QR Code Install
        </a>

        <div id="qrCode" class="qr-code" style="display:none;">
            <h3>Scan with your phone:</h3>
            <canvas id="qrCanvas"></canvas>
            <p><small>This QR code contains the installation command</small></p>
        </div>

        <div id="installStatus" style="display:none; margin-top:20px;">
            <h3>✅ Command Copied!</h3>
            <p>Open Termux and paste the command (long press and select "Paste")</p>
            <code style="background: #f4f4f4; padding: 10px; border-radius: 5px; display: block; margin: 10px 0; font-family: monospace; word-break: break-all;">
                curl -L https://chr-node.network/install | bash
            </code>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
    <script>
        function copyInstallCommand() {
            const command = 'curl -L https://chr-node.network/install | bash';
            
            // Copy to clipboard
            if (navigator.clipboard) {
                navigator.clipboard.writeText(command).then(() => {
                    showInstallStatus();
                });
            } else {
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = command;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                showInstallStatus();
            }
        }

        function showInstallStatus() {
            document.getElementById('installStatus').style.display = 'block';
            document.getElementById('installBtn').textContent = '✅ Copied!';
            document.getElementById('installBtn').style.background = '#28a745';
        }

        function showQR() {
            const command = 'curl -L https://chr-node.network/install | bash';
            const qrDiv = document.getElementById('qrCode');
            const canvas = document.getElementById('qrCanvas');
            
            qrDiv.style.display = 'block';
            
            QRCode.toCanvas(canvas, command, {
                width: 200,
                margin: 2,
                color: {
                    dark: '#000000',
                    light: '#FFFFFF'
                }
            });
        }
    </script>
</body>
</html>
```

### One-Click Installation Script

Create the script that the website will serve:
