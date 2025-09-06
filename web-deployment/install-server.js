const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3333;

// Middleware
app.use(cors());
app.use(express.static('public'));

// Serve installation scripts directly from static files
app.get('/scripts/termux-one-click-install.sh', (req, res) => {
    const scriptPath = path.join(__dirname, 'public', 'termux-one-click-install.sh');
    
    if (fs.existsSync(scriptPath)) {
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Content-Disposition', 'attachment; filename="termux-one-click-install.sh"');
        res.sendFile(scriptPath);
    } else {
        res.status(404).send('Standard installation script not found');
    }
});

app.get('/scripts/termux-install-with-build.sh', (req, res) => {
    const scriptPath = path.join(__dirname, 'public', 'termux-install-with-build.sh');
    
    if (fs.existsSync(scriptPath)) {
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Content-Disposition', 'attachment; filename="termux-install-with-build.sh"');
        res.sendFile(scriptPath);
    } else {
        res.status(404).send('Build pipeline installation script not found');
    }
});

app.get('/scripts/termux-master-dev-install.sh', (req, res) => {
    const scriptPath = path.join(__dirname, 'public', 'scripts', 'termux-master-dev-install.sh');
    
    if (fs.existsSync(scriptPath)) {
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Content-Disposition', 'attachment; filename="termux-master-dev-install.sh"');
        res.sendFile(scriptPath);
    } else {
        res.status(404).send('Master development installation script not found');
    }
});
app.use(express.json());

// Serve the installation script
app.get('/install', (req, res) => {
    const fs = require('fs');
    const path = require('path');
    
    // Try to serve the actual installation script directly
    const scriptPath = path.join(__dirname, '..', 'scripts', 'termux-one-click-install.sh');
    
    if (fs.existsSync(scriptPath)) {
        // Serve the actual installation script
        const actualScript = fs.readFileSync(scriptPath, 'utf8');
        
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Content-Disposition', 'attachment; filename="chr-node-install.sh"');
        res.send(actualScript);
    } else {
        // Fallback to stub script that tries to download from GitHub
        const installScript = `#!/data/data/com.termux/files/usr/bin/bash

# chr-node One-Click Installation
# Downloaded from: ${req.get('host')}
# Timestamp: ${new Date().toISOString()}

set -e

echo "🌐 chr-node One-Click Installation"
echo "=================================="
echo ""
echo "Downloading installation script from GitHub..."

# Check if GitHub CLI is available for private repo access
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo "📡 Using authenticated GitHub access..."
    gh api repos/CG-8663/chr-node/contents/scripts/termux-one-click-install.sh \\
        --jq '.content' | base64 -d > chr-node-install.sh
else
    echo "📡 Attempting public GitHub access..."
    curl -L -o chr-node-install.sh "${req.protocol}://${req.get('host')}/scripts/termux-one-click-install.sh"
fi

# Check if download was successful
if [ ! -f chr-node-install.sh ] || [ ! -s chr-node-install.sh ]; then
    echo "❌ Failed to download installation script"
    echo ""
    echo "If repository is private, try:"
    echo "1. Install GitHub CLI: pkg install gh"
    echo "2. Login: gh auth login"
    echo "3. Re-run this installer"
    echo ""
    echo "Or download script manually and run locally."
    exit 1
fi

# Make executable
chmod +x chr-node-install.sh

echo ""
echo "🚀 Starting chr-node installation..."
echo "This may take 5-10 minutes depending on your internet speed."
echo ""

# Run the installation
./chr-node-install.sh

echo ""
echo "✅ Installation complete!"
echo "Your chr-node is ready to use."
`;

        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Content-Disposition', 'attachment; filename="chr-node-install.sh"');
        res.send(installScript);
    }
});

// Serve installation statistics
app.get('/api/stats', (req, res) => {
    // In production, this would track real installation statistics
    res.json({
        totalInstalls: 1337,
        activeNodes: 456,
        averageInstallTime: '4.2 minutes',
        supportedDevices: [
            'Android 7.0+',
            'ARM64 (preferred)', 
            'ARMv7',
            'x86_64'
        ],
        lastUpdate: new Date().toISOString()
    });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'chr-node-installer',
        version: '1.0.0-beta',
        timestamp: new Date().toISOString()
    });
});

// Landing page
app.get('/', (req, res) => {
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>chr-node - One-Click Mobile Installation</title>
    <meta name="description" content="Install chr-node on Android with Termux in one click. Join the Chronara Network and start earning CHAI tokens.">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 700px;
            width: 100%;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            animation: fadeIn 0.8s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .logo {
            font-size: 4rem;
            margin-bottom: 20px;
            animation: bounce 2s infinite;
        }

        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }

        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5rem;
            font-weight: 700;
        }

        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.2rem;
            line-height: 1.6;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }

        .stat {
            padding: 20px;
            background: #f8f9fa;
            border-radius: 15px;
            border-left: 4px solid #667eea;
        }

        .stat-number {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
        }

        .stat-label {
            color: #666;
            font-size: 0.9rem;
            margin-top: 5px;
        }

        .requirements {
            background: linear-gradient(45deg, #fff3cd, #ffeaa7);
            border: 1px solid #ffeaa7;
            border-radius: 15px;
            padding: 25px;
            margin: 30px 0;
            text-align: left;
        }

        .requirements h3 {
            color: #333;
            margin-bottom: 15px;
            text-align: center;
        }

        .requirements ul {
            list-style: none;
            padding: 0;
        }

        .requirements li {
            padding: 8px 0;
            position: relative;
            padding-left: 30px;
        }

        .requirements li:before {
            content: '✅';
            position: absolute;
            left: 0;
            top: 8px;
        }

        .install-section {
            margin: 40px 0;
        }

        .install-button {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 18px 45px;
            font-size: 1.3rem;
            font-weight: 600;
            border-radius: 50px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 15px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }

        .install-button:hover {
            transform: translateY(-3px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
        }

        .install-button.secondary {
            background: linear-gradient(45deg, #28a745, #20c997);
            box-shadow: 0 4px 15px rgba(40, 167, 69, 0.4);
        }

        .install-button.secondary:hover {
            box-shadow: 0 6px 20px rgba(40, 167, 69, 0.6);
        }

        .steps {
            text-align: left;
            margin: 40px 0;
        }

        .step {
            margin: 20px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 15px;
            border-left: 5px solid #667eea;
            position: relative;
            transition: transform 0.2s ease;
        }

        .step:hover {
            transform: translateX(5px);
        }

        .step-number {
            position: absolute;
            left: -15px;
            top: 15px;
            width: 30px;
            height: 30px;
            background: #667eea;
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }

        .step-content {
            margin-left: 20px;
        }

        .step-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
        }

        .step-description {
            color: #666;
            font-size: 0.95rem;
            line-height: 1.5;
        }

        .command-box {
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            margin: 20px 0;
            position: relative;
            overflow-x: auto;
        }

        .copy-button {
            position: absolute;
            top: 10px;
            right: 10px;
            background: #4299e1;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 5px;
            font-size: 0.8rem;
            cursor: pointer;
        }

        .success-message {
            display: none;
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }

        .footer {
            margin-top: 40px;
            padding-top: 30px;
            border-top: 1px solid #e9ecef;
            color: #666;
        }

        .footer a {
            color: #667eea;
            text-decoration: none;
        }

        .footer a:hover {
            text-decoration: underline;
        }

        @media (max-width: 768px) {
            .container {
                margin: 10px;
                padding: 30px 20px;
            }
            
            h1 {
                font-size: 2rem;
            }
            
            .logo {
                font-size: 3rem;
            }
            
            .install-button {
                width: 100%;
                margin: 10px 0;
            }
        }

        .qr-section {
            margin: 30px 0;
            padding: 25px;
            background: #f8f9fa;
            border-radius: 15px;
            display: none;
        }

        #qrCode canvas {
            border: 1px solid #ddd;
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌐</div>
        <h1>chr-node</h1>
        <p class="subtitle">
            Mobile P2P Network Infrastructure for Emerging Markets<br>
            Transform your Android device into a powerful blockchain node with NFT-gated AI capabilities
        </p>

        <div style="background: #e8f4fd; padding: 25px; border-radius: 15px; margin: 30px 0; text-align: left;">
            <h3 style="text-align: center; color: #333; margin-bottom: 20px;">🚀 What is chr-node?</h3>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px;">
                <div>
                    <h4>📱 Mobile-First Architecture</h4>
                    <p>Deploy P2P infrastructure on any Android device via Termux with ultra-lightweight design for 1GB RAM devices.</p>
                </div>
                <div>
                    <h4>🔐 NFT-Gated Access</h4>
                    <p>Tiered feature access based on Chronara Node Pass NFT ownership (Basic/Standard/Premium levels).</p>
                </div>
            </div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div>
                    <h4>🤖 AI Integration</h4>
                    <p>Gemini and Claude AI agents for personalized assistance, trading insights, and NFT intelligence.</p>
                </div>
                <div>
                    <h4>🌍 Emerging Markets Focus</h4>
                    <p>Democratize P2P network participation by making blockchain infrastructure accessible on mobile devices globally.</p>
                </div>
            </div>
        </div>

        <div class="stats" id="stats">
            <div class="stat">
                <div class="stat-number" id="totalInstalls">-</div>
                <div class="stat-label">Total Installs</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="activeNodes">-</div>
                <div class="stat-label">Active Nodes</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="avgInstallTime">-</div>
                <div class="stat-label">Avg Install Time</div>
            </div>
        </div>

        <div class="requirements">
            <h3>📱 Requirements</h3>
            <ul>
                <li>Android 7.0+ device with 1GB+ RAM</li>
                <li>Termux app installed from F-Droid</li>
                <li>Chronara Node Pass NFT (any tier)</li>
                <li>Internet connection (WiFi or mobile data)</li>
                <li>500MB free storage space</li>
            </ul>
        </div>

        <div class="install-section">
            <h3>Choose Your Installation Method:</h3>
            
            <div style="margin: 20px 0;">
                <h4>🚀 Standard Install (Fixed Web Interface)</h4>
                <p style="color: #666; margin-bottom: 15px;">Complete chr-node installation with fixed web interface startup</p>
                <a href="/scripts/termux-one-click-install.sh" class="install-button" onclick="trackInstall('standard')">
                    📱 Download Standard Script
                </a>
                <button class="install-button secondary" onclick="copyCommand('standard')">
                    📋 Copy Standard Command
                </button>
            </div>
            
            <div style="margin: 30px 0; padding: 20px; background: #e8f4fd; border-radius: 10px;">
                <h4>🔨 Build Pipeline Install (Recommended for Testing)</h4>
                <p style="color: #666; margin-bottom: 15px;">Compile chr-node + diode client from source with platform optimization</p>
                <a href="/scripts/termux-install-with-build.sh" class="install-button" onclick="trackInstall('build')">
                    📱 Download Build Script
                </a>
                <button class="install-button secondary" onclick="copyCommand('build')">
                    📋 Copy Build Command
                </button>
            </div>
            
            <div style="margin: 30px 0; padding: 20px; background: #fff3cd; border: 2px solid #ffc107; border-radius: 10px;">
                <h4>🔧 Master Development Install (SSH Auth Required)</h4>
                <p style="color: #666; margin-bottom: 15px;"><strong>For Developers:</strong> Build, test, and publish binaries back to repository with SSH authentication</p>
                <a href="/scripts/termux-master-dev-install.sh" class="install-button" onclick="trackInstall('master-dev')" style="background: linear-gradient(45deg, #ff6b6b, #ee5a24);">
                    🔧 Download Master Dev Script
                </a>
                <button class="install-button secondary" onclick="copyCommand('master-dev')">
                    📋 Copy Master Dev Command
                </button>
                <div style="margin-top: 15px; padding: 15px; background: rgba(255,193,7,0.1); border-radius: 8px;">
                    <small><strong>⚠️ Requirements:</strong> GitHub CLI authentication, SSH keys configured, push access to CG-8663/chr-node repository</small>
                </div>
            </div>
            
        </div>

        <div class="command-box" id="commandBox" style="display:none;">
            <button class="copy-button" onclick="copyToClipboard()">Copy</button>
            <code id="installCommand">curl -L http://localhost:3334/scripts/termux-one-click-install.sh | bash</code>
        </div>

        <div class="success-message" id="successMessage">
            <strong>✅ Ready to install!</strong> Open Termux and paste the command.
        </div>


        <div class="steps">
            <h3>Installation Steps:</h3>
            
            <div class="step">
                <div class="step-number">1</div>
                <div class="step-content">
                    <div class="step-title">Install Termux</div>
                    <div class="step-description">
                        Download Termux from F-Droid (recommended) or Google Play Store
                        <br><a href="https://f-droid.org/packages/com.termux/" target="_blank">→ Get Termux from F-Droid</a>
                    </div>
                </div>
            </div>

            <div class="step">
                <div class="step-number">2</div>
                <div class="step-content">
                    <div class="step-title">Run Installation</div>
                    <div class="step-description">
                        Copy the command above and paste it in Termux. The installation will run automatically.
                    </div>
                </div>
            </div>

            <div class="step">
                <div class="step-number">3</div>
                <div class="step-content">
                    <div class="step-title">Connect Your Wallet</div>
                    <div class="step-description">
                        Once installed, open the web interface and connect your wallet to verify your Chronara Node Pass NFT.
                    </div>
                </div>
            </div>

            <div class="step">
                <div class="step-number">4</div>
                <div class="step-content">
                    <div class="step-title">Start Earning</div>
                    <div class="step-description">
                        Your node will start participating in the network and earning CHAI tokens automatically.
                    </div>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>
                <strong>chr-node v1.0.0-beta</strong> - 
                🚀 <a href="https://github.com/CG-8663/chr-node/releases/tag/v1.0.0-beta">Download Binaries</a> •
                📖 <a href="https://docs.chronara.network">Documentation</a> •
                💬 <a href="https://discord.gg/chronara">Discord Community</a> •
                📧 <a href="mailto:support@chronara.network">Support</a>
            </p>
            <p style="margin-top: 15px;">
                <small>
                    chr-node is open source • 
                    <a href="https://github.com/CG-8663/chr-node">View on GitHub</a>
                </small>
            </p>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
    <script>
        // Load installation statistics
        async function loadStats() {
            try {
                const response = await fetch('/api/stats');
                const stats = await response.json();
                
                document.getElementById('totalInstalls').textContent = stats.totalInstalls.toLocaleString();
                document.getElementById('activeNodes').textContent = stats.activeNodes.toLocaleString();
                document.getElementById('avgInstallTime').textContent = stats.averageInstallTime;
            } catch (error) {
                console.log('Stats loading failed:', error);
                document.getElementById('totalInstalls').textContent = '1000+';
                document.getElementById('activeNodes').textContent = '400+';
                document.getElementById('avgInstallTime').textContent = '4.2min';
            }
        }

        let currentInstallType = 'standard';
        
        function copyCommand(type = 'standard') {
            currentInstallType = type;
            const commandBox = document.getElementById('commandBox');
            const commandElement = document.getElementById('installCommand');
            
            let command;
            if (type === 'build') {
                command = 'curl -L ' + window.location.origin + '/scripts/termux-install-with-build.sh | bash';
                commandElement.textContent = command;
            } else if (type === 'master-dev') {
                command = 'curl -L ' + window.location.origin + '/scripts/termux-master-dev-install.sh | bash';
                commandElement.textContent = command;
            } else {
                command = 'curl -L ' + window.location.origin + '/scripts/termux-one-click-install.sh | bash';
                commandElement.textContent = command;
            }
            
            commandBox.style.display = 'block';
            copyToClipboard();
        }

        function copyToClipboard() {
            const commandElement = document.getElementById('installCommand');
            const command = commandElement.textContent;
            
            if (navigator.clipboard) {
                navigator.clipboard.writeText(command).then(() => {
                    showSuccess();
                });
            } else {
                // Fallback
                const textArea = document.createElement('textarea');
                textArea.value = command;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                showSuccess();
            }
        }

        function showSuccess() {
            document.getElementById('successMessage').style.display = 'block';
            setTimeout(() => {
                document.getElementById('successMessage').style.display = 'none';
            }, 5000);
        }


        function trackInstall(method) {
            // Track installation method for analytics
            console.log('Install tracked:', method);
            
            // You could send this to an analytics service
            fetch('/api/track-install', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ method, timestamp: new Date().toISOString() })
            }).catch(e => console.log('Tracking failed:', e));
        }

        // Load stats when page loads
        document.addEventListener('DOMContentLoaded', loadStats);
    </script>
</body>
</html>
    `;
    
    res.send(html);
});

// Track installations (optional analytics)
app.post('/api/track-install', (req, res) => {
    const { method, timestamp } = req.body;
    
    // In production, you'd save this to a database
    console.log(`Installation tracked: ${method} at ${timestamp}`);
    
    res.json({ status: 'tracked' });
});

app.listen(PORT, () => {
    console.log(`🌐 chr-node Installation Server running on port ${PORT}`);
    console.log(`📱 Installation URL: http://localhost:${PORT}/install`);
    console.log(`🖥️  Admin interface: http://localhost:${PORT}`);
});

module.exports = app;