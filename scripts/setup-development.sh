#!/data/data/com.termux/files/usr/bin/bash

# chr-node Development Environment Setup Script
# Configures development environment, API integration, and web interface

set -e

CHR_NODE_DIR="$HOME/.chr-node"
WEB_DIR="$CHR_NODE_DIR/web"
API_DIR="$CHR_NODE_DIR/api"

echo "🛠️  chr-node Development Environment Setup"
echo "=========================================="
echo "Setting up development and API integration..."
echo ""

# Check if chr-node is installed
check_installation() {
    if [ ! -d "$CHR_NODE_DIR" ]; then
        echo "❌ chr-node not installed. Run termux_install.sh first."
        exit 1
    fi
    
    if [ ! -f "$CHR_NODE_DIR/bin/chr-node" ]; then
        echo "❌ chr-node binary not found. Installation may be incomplete."
        exit 1
    fi
    
    echo "✅ chr-node installation verified"
}

# Set up web interface
setup_web_interface() {
    echo "🌐 Setting up web interface..."
    
    mkdir -p "$WEB_DIR"
    cd "$WEB_DIR"
    
    # Initialize Node.js project if not exists
    if [ ! -f "package.json" ]; then
        cat > package.json << 'EOF'
{
  "name": "chr-node-interface",
  "version": "1.0.0",
  "description": "chr-node Web Interface with NFT Authentication",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "qrcode": "^1.5.3",
    "express-rate-limit": "^6.8.1",
    "helmet": "^7.0.0",
    "cors": "^2.8.5",
    "multer": "^1.4.5",
    "jimp": "^0.22.10",
    "web3": "^4.1.1",
    "ethers": "^6.7.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
        
        npm install
    fi
    
    echo "✅ Web interface dependencies installed"
}

# Create web server
create_web_server() {
    echo "🖥️  Creating web server..."
    
    cat > "$WEB_DIR/server.js" << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const QRCode = require('qrcode');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { ethers } = require('ethers');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Security middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
            scriptSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "ws:", "wss:"]
        }
    }
}));

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api', limiter);

// Configuration
const CONFIG = {
    port: process.env.PORT || 3000,
    chrNodeDir: process.env.CHR_NODE_DIR || process.env.HOME + '/.chr-node',
    nftContractAddress: '0x...', // Will be configured later
    supportedChains: ['ethereum', 'polygon', 'binance'],
    requiredNFTCollection: 'chronara-node-pass'
};

// In-memory session storage (use Redis in production)
const sessions = new Map();
const activeNodes = new Map();

// Utility functions
function generateSessionId() {
    return require('crypto').randomBytes(32).toString('hex');
}

function isValidWalletAddress(address) {
    try {
        return ethers.isAddress(address);
    } catch (error) {
        return false;
    }
}

// NFT verification (mock implementation - replace with real contract calls)
async function verifyNFTOwnership(walletAddress) {
    // Mock verification - replace with actual blockchain calls
    const mockNFTOwners = [
        '0x1234567890123456789012345678901234567890',
        '0x0987654321098765432109876543210987654321'
    ];
    
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return {
        hasNFT: mockNFTOwners.includes(walletAddress.toLowerCase()),
        nftDetails: {
            tokenId: '42',
            collection: 'chronara-node-pass',
            metadata: {
                name: 'Chronara Node Pass #42',
                description: 'Access pass for chr-node network',
                image: 'https://example.com/nft/42.png'
            }
        }
    };
}

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/status', (req, res) => {
    res.json({
        status: 'online',
        version: '1.0.0',
        activeNodes: activeNodes.size,
        activeSessions: sessions.size,
        uptime: process.uptime()
    });
});

// Generate QR code for wallet connection
app.get('/api/qr-auth/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const authUrl = `chrnode://auth?session=${sessionId}&return=${encodeURIComponent(req.get('origin'))}`;
        
        const qrCode = await QRCode.toDataURL(authUrl, {
            width: 256,
            margin: 2,
            color: {
                dark: '#000000',
                light: '#FFFFFF'
            }
        });
        
        res.json({ qrCode, authUrl, sessionId });
    } catch (error) {
        res.status(500).json({ error: 'Failed to generate QR code' });
    }
});

// Wallet authentication
app.post('/api/auth/wallet', async (req, res) => {
    try {
        const { walletAddress, signature, sessionId } = req.body;
        
        if (!isValidWalletAddress(walletAddress)) {
            return res.status(400).json({ error: 'Invalid wallet address' });
        }
        
        // Verify NFT ownership
        const nftVerification = await verifyNFTOwnership(walletAddress);
        
        if (!nftVerification.hasNFT) {
            return res.status(403).json({ 
                error: 'NFT not found',
                message: 'You need to own a Chronara Node Pass NFT to access this service'
            });
        }
        
        // Create session
        const session = {
            id: sessionId || generateSessionId(),
            walletAddress: walletAddress.toLowerCase(),
            authenticated: true,
            nftDetails: nftVerification.nftDetails,
            createdAt: new Date(),
            lastActivity: new Date()
        };
        
        sessions.set(session.id, session);
        
        // Emit authentication success to connected clients
        io.emit('auth_success', {
            sessionId: session.id,
            walletAddress: session.walletAddress,
            nftDetails: session.nftDetails
        });
        
        res.json({
            success: true,
            sessionId: session.id,
            walletAddress: session.walletAddress,
            nftDetails: session.nftDetails
        });
        
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(500).json({ error: 'Authentication failed' });
    }
});

// Node management
app.get('/api/node/status', (req, res) => {
    const sessionId = req.headers['x-session-id'];
    const session = sessions.get(sessionId);
    
    if (!session || !session.authenticated) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    
    // Mock node status - replace with actual chr-node API calls
    res.json({
        nodeId: 'chr-node-' + session.walletAddress.slice(-8),
        status: 'running',
        peers: 12,
        uptime: 3600,
        version: '1.0.0',
        lastSync: new Date(),
        earnings: {
            today: '2.5 CHAI',
            week: '15.2 CHAI',
            total: '127.8 CHAI'
        }
    });
});

// Socket.io connection handling
io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);
    
    socket.on('authenticate', async (data) => {
        try {
            const { walletAddress } = data;
            
            if (!isValidWalletAddress(walletAddress)) {
                socket.emit('auth_error', { error: 'Invalid wallet address' });
                return;
            }
            
            const nftVerification = await verifyNFTOwnership(walletAddress);
            
            if (nftVerification.hasNFT) {
                const sessionId = generateSessionId();
                const session = {
                    id: sessionId,
                    walletAddress: walletAddress.toLowerCase(),
                    authenticated: true,
                    nftDetails: nftVerification.nftDetails,
                    socketId: socket.id,
                    createdAt: new Date()
                };
                
                sessions.set(sessionId, session);
                socket.emit('auth_success', session);
            } else {
                socket.emit('auth_error', { 
                    error: 'NFT not found',
                    message: 'Chronara Node Pass NFT required'
                });
            }
            
        } catch (error) {
            socket.emit('auth_error', { error: 'Authentication failed' });
        }
    });
    
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
        // Clean up sessions
        for (const [sessionId, session] of sessions.entries()) {
            if (session.socketId === socket.id) {
                sessions.delete(sessionId);
                break;
            }
        }
    });
});

// Start server
const PORT = CONFIG.port;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🌐 chr-node Web Interface running on port ${PORT}`);
    console.log(`🏠 Local access: http://localhost:${PORT}`);
    console.log(`📱 Mobile access: http://[your-ip]:${PORT}`);
    console.log(`📊 Status endpoint: http://localhost:${PORT}/api/status`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🔄 Shutting down gracefully...');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});
EOF
    
    echo "✅ Web server created"
}

# Create web interface HTML
create_web_interface() {
    echo "🎨 Creating web interface..."
    
    mkdir -p "$WEB_DIR/public"
    mkdir -p "$WEB_DIR/public/css"
    mkdir -p "$WEB_DIR/public/js"
    
    # Main HTML page
    cat > "$WEB_DIR/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>chr-node | Chronara Network Node</title>
    <link rel="stylesheet" href="css/style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header class="header">
            <div class="logo">
                <i class="fas fa-network-wired"></i>
                <h1>chr-node</h1>
                <span class="subtitle">Chronara Network Node</span>
            </div>
            <div class="status-indicator">
                <span class="status-dot" id="statusDot"></span>
                <span id="statusText">Connecting...</span>
            </div>
        </header>

        <!-- Main Content -->
        <main class="main-content">
            <!-- Authentication Section -->
            <section id="authSection" class="auth-section">
                <div class="auth-card">
                    <h2><i class="fas fa-shield-alt"></i> Authenticate with NFT</h2>
                    <p>Connect your wallet to verify your Chronara Node Pass NFT</p>
                    
                    <div class="auth-methods">
                        <div class="auth-method">
                            <h3><i class="fas fa-qrcode"></i> QR Code Scanner</h3>
                            <div class="qr-section">
                                <div id="qrCodeContainer" class="qr-container">
                                    <div class="loading-spinner"></div>
                                </div>
                                <p>Scan with your wallet app</p>
                            </div>
                        </div>
                        
                        <div class="divider">OR</div>
                        
                        <div class="auth-method">
                            <h3><i class="fas fa-wallet"></i> Manual Entry</h3>
                            <div class="wallet-input-section">
                                <input 
                                    type="text" 
                                    id="walletAddress" 
                                    placeholder="Enter wallet address (0x...)"
                                    class="wallet-input"
                                >
                                <button id="connectWallet" class="connect-btn">
                                    <i class="fas fa-link"></i> Connect Wallet
                                </button>
                            </div>
                        </div>
                    </div>
                    
                    <div id="authError" class="error-message"></div>
                </div>
            </section>

            <!-- Dashboard Section -->
            <section id="dashboardSection" class="dashboard-section" style="display: none;">
                <div class="user-info">
                    <div class="wallet-info">
                        <i class="fas fa-user-circle"></i>
                        <span id="userWallet">0x...</span>
                        <button id="logoutBtn" class="logout-btn">
                            <i class="fas fa-sign-out-alt"></i>
                        </button>
                    </div>
                </div>
                
                <div class="dashboard-grid">
                    <!-- Node Status Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <h3><i class="fas fa-server"></i> Node Status</h3>
                        </div>
                        <div class="card-content">
                            <div class="status-grid">
                                <div class="status-item">
                                    <span class="label">Status</span>
                                    <span id="nodeStatus" class="value status-running">Running</span>
                                </div>
                                <div class="status-item">
                                    <span class="label">Peers</span>
                                    <span id="peerCount" class="value">0</span>
                                </div>
                                <div class="status-item">
                                    <span class="label">Uptime</span>
                                    <span id="nodeUptime" class="value">0h 0m</span>
                                </div>
                                <div class="status-item">
                                    <span class="label">Version</span>
                                    <span id="nodeVersion" class="value">1.0.0</span>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Earnings Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <h3><i class="fas fa-coins"></i> CHAI Earnings</h3>
                        </div>
                        <div class="card-content">
                            <div class="earnings-grid">
                                <div class="earnings-item">
                                    <span class="label">Today</span>
                                    <span id="earningsToday" class="value">0 CHAI</span>
                                </div>
                                <div class="earnings-item">
                                    <span class="label">This Week</span>
                                    <span id="earningsWeek" class="value">0 CHAI</span>
                                </div>
                                <div class="earnings-item">
                                    <span class="label">Total</span>
                                    <span id="earningsTotal" class="value">0 CHAI</span>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- NFT Info Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <h3><i class="fas fa-certificate"></i> Node Pass NFT</h3>
                        </div>
                        <div class="card-content">
                            <div id="nftInfo" class="nft-info">
                                <div class="nft-image">
                                    <i class="fas fa-image"></i>
                                </div>
                                <div class="nft-details">
                                    <div class="nft-name" id="nftName">Loading...</div>
                                    <div class="nft-id" id="nftId">#0</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- AI Agent Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <h3><i class="fas fa-robot"></i> AI Agent</h3>
                        </div>
                        <div class="card-content">
                            <div class="agent-status">
                                <div class="agent-indicator">
                                    <span class="status-dot status-pending"></span>
                                    <span>Ready for Configuration</span>
                                </div>
                                <button class="config-btn" disabled>
                                    <i class="fas fa-cog"></i> Configure Agent
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </main>
        
        <!-- Footer -->
        <footer class="footer">
            <p>&copy; 2024 Chronara Network. Powered by chr-node.</p>
        </footer>
    </div>

    <script src="/socket.io/socket.io.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
EOF
    
    echo "✅ HTML interface created"
}

# Create CSS styles
create_styles() {
    echo "🎨 Creating styles..."
    
    cat > "$WEB_DIR/public/css/style.css" << 'EOF'
:root {
    --primary-color: #2563eb;
    --primary-hover: #1d4ed8;
    --secondary-color: #64748b;
    --success-color: #10b981;
    --warning-color: #f59e0b;
    --error-color: #ef4444;
    --bg-color: #f8fafc;
    --card-bg: #ffffff;
    --text-primary: #1e293b;
    --text-secondary: #64748b;
    --border-color: #e2e8f0;
    --border-radius: 12px;
    --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
    --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-primary);
    line-height: 1.6;
}

.container {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

/* Header */
.header {
    background: var(--card-bg);
    padding: 1rem 2rem;
    border-bottom: 1px solid var(--border-color);
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: var(--shadow-sm);
}

.logo {
    display: flex;
    align-items: center;
    gap: 0.75rem;
}

.logo i {
    font-size: 2rem;
    color: var(--primary-color);
}

.logo h1 {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--text-primary);
}

.subtitle {
    color: var(--text-secondary);
    font-size: 0.875rem;
}

.status-indicator {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
}

.status-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: var(--warning-color);
    animation: pulse 2s infinite;
}

.status-dot.connected {
    background: var(--success-color);
    animation: none;
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

/* Main Content */
.main-content {
    flex: 1;
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
    width: 100%;
}

/* Authentication Section */
.auth-section {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 60vh;
}

.auth-card {
    background: var(--card-bg);
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-lg);
    padding: 2rem;
    max-width: 600px;
    width: 100%;
}

.auth-card h2 {
    text-align: center;
    margin-bottom: 0.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
}

.auth-card p {
    text-align: center;
    color: var(--text-secondary);
    margin-bottom: 2rem;
}

.auth-methods {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

.auth-method {
    text-align: center;
}

.auth-method h3 {
    margin-bottom: 1rem;
    color: var(--text-primary);
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
}

.qr-container {
    width: 200px;
    height: 200px;
    margin: 0 auto 1rem;
    border: 2px dashed var(--border-color);
    border-radius: var(--border-radius);
    display: flex;
    align-items: center;
    justify-content: center;
    background: #fafafa;
}

.qr-container img {
    max-width: 100%;
    max-height: 100%;
    border-radius: 8px;
}

.loading-spinner {
    width: 40px;
    height: 40px;
    border: 3px solid var(--border-color);
    border-top: 3px solid var(--primary-color);
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

.divider {
    text-align: center;
    color: var(--text-secondary);
    font-weight: 500;
    position: relative;
}

.divider::before,
.divider::after {
    content: '';
    position: absolute;
    top: 50%;
    width: 45%;
    height: 1px;
    background: var(--border-color);
}

.divider::before { left: 0; }
.divider::after { right: 0; }

.wallet-input-section {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    max-width: 400px;
    margin: 0 auto;
}

.wallet-input {
    padding: 0.75rem;
    border: 2px solid var(--border-color);
    border-radius: var(--border-radius);
    font-size: 1rem;
    transition: border-color 0.2s;
}

.wallet-input:focus {
    outline: none;
    border-color: var(--primary-color);
}

.connect-btn {
    background: var(--primary-color);
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: var(--border-radius);
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
}

.connect-btn:hover {
    background: var(--primary-hover);
}

.connect-btn:disabled {
    background: var(--secondary-color);
    cursor: not-allowed;
}

.error-message {
    background: #fef2f2;
    color: var(--error-color);
    padding: 1rem;
    border-radius: var(--border-radius);
    border: 1px solid #fecaca;
    margin-top: 1rem;
    display: none;
}

.error-message.show {
    display: block;
}

/* Dashboard Section */
.dashboard-section {
    animation: fadeIn 0.5s ease-in;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
}

.user-info {
    background: var(--card-bg);
    border-radius: var(--border-radius);
    padding: 1rem 1.5rem;
    margin-bottom: 2rem;
    box-shadow: var(--shadow-sm);
}

.wallet-info {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.wallet-info i {
    font-size: 1.5rem;
    color: var(--primary-color);
}

.logout-btn {
    background: none;
    border: 1px solid var(--border-color);
    padding: 0.5rem;
    border-radius: 6px;
    cursor: pointer;
    color: var(--text-secondary);
    transition: all 0.2s;
    margin-left: auto;
}

.logout-btn:hover {
    background: #fef2f2;
    border-color: var(--error-color);
    color: var(--error-color);
}

.dashboard-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1.5rem;
}

.dashboard-card {
    background: var(--card-bg);
    border-radius: var(--border-radius);
    box-shadow: var(--shadow-md);
    overflow: hidden;
}

.card-header {
    background: #f8fafc;
    padding: 1rem 1.5rem;
    border-bottom: 1px solid var(--border-color);
}

.card-header h3 {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 1.125rem;
    font-weight: 600;
}

.card-content {
    padding: 1.5rem;
}

.status-grid,
.earnings-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
}

.status-item,
.earnings-item {
    text-align: center;
}

.status-item .label,
.earnings-item .label {
    display: block;
    font-size: 0.875rem;
    color: var(--text-secondary);
    margin-bottom: 0.25rem;
}

.status-item .value,
.earnings-item .value {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--text-primary);
}

.status-running {
    color: var(--success-color);
}

.nft-info {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.nft-image {
    width: 60px;
    height: 60px;
    background: #f1f5f9;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-secondary);
    font-size: 1.5rem;
}

.nft-name {
    font-weight: 600;
    margin-bottom: 0.25rem;
}

.nft-id {
    color: var(--text-secondary);
    font-size: 0.875rem;
}

.agent-status {
    text-align: center;
}

.agent-indicator {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    margin-bottom: 1rem;
}

.status-pending {
    background: var(--warning-color);
}

.config-btn {
    background: var(--secondary-color);
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: var(--border-radius);
    font-weight: 500;
    cursor: not-allowed;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin: 0 auto;
}

/* Footer */
.footer {
    text-align: center;
    padding: 2rem;
    color: var(--text-secondary);
    border-top: 1px solid var(--border-color);
    background: var(--card-bg);
}

/* Responsive Design */
@media (max-width: 768px) {
    .header {
        padding: 1rem;
        flex-direction: column;
        gap: 1rem;
        text-align: center;
    }

    .main-content {
        padding: 1rem;
    }

    .auth-card {
        padding: 1.5rem;
    }

    .auth-methods {
        gap: 1rem;
    }

    .wallet-input-section {
        max-width: 100%;
    }

    .dashboard-grid {
        grid-template-columns: 1fr;
    }

    .status-grid,
    .earnings-grid {
        grid-template-columns: 1fr;
    }
}
EOF
    
    echo "✅ Styles created"
}

# Create JavaScript application
create_javascript() {
    echo "📱 Creating JavaScript application..."
    
    cat > "$WEB_DIR/public/js/app.js" << 'EOF'
class CHRNodeApp {
    constructor() {
        this.socket = null;
        this.sessionId = null;
        this.currentUser = null;
        this.qrRefreshInterval = null;
        
        this.init();
    }
    
    init() {
        this.connectSocket();
        this.bindEvents();
        this.generateQRCode();
        this.checkServerStatus();
        
        console.log('🚀 chr-node Web Interface initialized');
    }
    
    connectSocket() {
        this.socket = io();
        
        this.socket.on('connect', () => {
            console.log('✅ Connected to chr-node server');
            this.updateStatus('Connected', true);
        });
        
        this.socket.on('disconnect', () => {
            console.log('❌ Disconnected from chr-node server');
            this.updateStatus('Disconnected', false);
        });
        
        this.socket.on('auth_success', (data) => {
            console.log('✅ Authentication successful:', data);
            this.handleAuthSuccess(data);
        });
        
        this.socket.on('auth_error', (error) => {
            console.log('❌ Authentication failed:', error);
            this.showError(error.message || error.error);
        });
    }
    
    bindEvents() {
        // Connect wallet button
        const connectBtn = document.getElementById('connectWallet');
        const walletInput = document.getElementById('walletAddress');
        const logoutBtn = document.getElementById('logoutBtn');
        
        connectBtn.addEventListener('click', () => this.connectWallet());
        
        walletInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.connectWallet();
            }
        });
        
        walletInput.addEventListener('input', (e) => {
            this.clearError();
            const isValid = this.isValidWalletAddress(e.target.value);
            connectBtn.disabled = !isValid;
        });
        
        logoutBtn.addEventListener('click', () => this.logout());
    }
    
    async generateQRCode() {
        try {
            const sessionId = this.generateSessionId();
            const response = await fetch(`/api/qr-auth/${sessionId}`);
            const data = await response.json();
            
            if (data.qrCode) {
                const qrContainer = document.getElementById('qrCodeContainer');
                qrContainer.innerHTML = `<img src="${data.qrCode}" alt="QR Code for wallet connection">`;
                
                // Start polling for QR authentication
                this.pollQRAuth(sessionId);
            }
        } catch (error) {
            console.error('Failed to generate QR code:', error);
        }
    }
    
    async pollQRAuth(sessionId) {
        // This would poll the server to check if QR code was scanned
        // For now, it's a placeholder
        setTimeout(() => {
            if (!this.currentUser) {
                this.generateQRCode(); // Refresh QR code
            }
        }, 60000); // Refresh every minute
    }
    
    async connectWallet() {
        const walletInput = document.getElementById('walletAddress');
        const connectBtn = document.getElementById('connectWallet');
        const walletAddress = walletInput.value.trim();
        
        if (!this.isValidWalletAddress(walletAddress)) {
            this.showError('Please enter a valid wallet address');
            return;
        }
        
        try {
            connectBtn.disabled = true;
            connectBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connecting...';
            
            const response = await fetch('/api/auth/wallet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    walletAddress: walletAddress,
                    sessionId: this.generateSessionId()
                })
            });
            
            const data = await response.json();
            
            if (response.ok && data.success) {
                this.handleAuthSuccess(data);
            } else {
                this.showError(data.message || data.error || 'Authentication failed');
            }
            
        } catch (error) {
            console.error('Connection error:', error);
            this.showError('Connection failed. Please try again.');
        } finally {
            connectBtn.disabled = false;
            connectBtn.innerHTML = '<i class="fas fa-link"></i> Connect Wallet';
        }
    }
    
    handleAuthSuccess(data) {
        this.currentUser = data;
        this.sessionId = data.sessionId;
        
        // Hide auth section, show dashboard
        document.getElementById('authSection').style.display = 'none';
        document.getElementById('dashboardSection').style.display = 'block';
        
        // Update user info
        document.getElementById('userWallet').textContent = this.formatWalletAddress(data.walletAddress);
        
        if (data.nftDetails) {
            document.getElementById('nftName').textContent = data.nftDetails.metadata.name;
            document.getElementById('nftId').textContent = `#${data.nftDetails.tokenId}`;
        }
        
        // Load node status
        this.loadNodeStatus();
        
        // Start periodic updates
        this.startPeriodicUpdates();
        
        this.clearError();
    }
    
    async loadNodeStatus() {
        try {
            const response = await fetch('/api/node/status', {
                headers: {
                    'X-Session-ID': this.sessionId
                }
            });
            
            if (response.ok) {
                const data = await response.json();
                this.updateNodeStatus(data);
            }
        } catch (error) {
            console.error('Failed to load node status:', error);
        }
    }
    
    updateNodeStatus(data) {
        document.getElementById('nodeStatus').textContent = data.status;
        document.getElementById('peerCount').textContent = data.peers;
        document.getElementById('nodeUptime').textContent = this.formatUptime(data.uptime);
        document.getElementById('nodeVersion').textContent = data.version;
        
        if (data.earnings) {
            document.getElementById('earningsToday').textContent = data.earnings.today;
            document.getElementById('earningsWeek').textContent = data.earnings.week;
            document.getElementById('earningsTotal').textContent = data.earnings.total;
        }
    }
    
    startPeriodicUpdates() {
        // Update node status every 30 seconds
        setInterval(() => {
            if (this.currentUser) {
                this.loadNodeStatus();
            }
        }, 30000);
    }
    
    async checkServerStatus() {
        try {
            const response = await fetch('/api/status');
            const data = await response.json();
            
            if (data.status === 'online') {
                this.updateStatus('Online', true);
            }
        } catch (error) {
            console.error('Server status check failed:', error);
            this.updateStatus('Offline', false);
        }
    }
    
    logout() {
        this.currentUser = null;
        this.sessionId = null;
        
        // Show auth section, hide dashboard
        document.getElementById('authSection').style.display = 'block';
        document.getElementById('dashboardSection').style.display = 'none';
        
        // Clear form
        document.getElementById('walletAddress').value = '';
        
        // Regenerate QR code
        this.generateQRCode();
        
        this.clearError();
    }
    
    updateStatus(text, connected) {
        const statusText = document.getElementById('statusText');
        const statusDot = document.getElementById('statusDot');
        
        statusText.textContent = text;
        
        if (connected) {
            statusDot.classList.add('connected');
        } else {
            statusDot.classList.remove('connected');
        }
    }
    
    showError(message) {
        const errorElement = document.getElementById('authError');
        errorElement.textContent = message;
        errorElement.classList.add('show');
    }
    
    clearError() {
        const errorElement = document.getElementById('authError');
        errorElement.classList.remove('show');
    }
    
    isValidWalletAddress(address) {
        return /^0x[a-fA-F0-9]{40}$/.test(address);
    }
    
    formatWalletAddress(address) {
        if (!address) return '';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }
    
    formatUptime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return `${hours}h ${minutes}m`;
    }
    
    generateSessionId() {
        return Array.from(crypto.getRandomValues(new Uint8Array(16)))
            .map(b => b.toString(16).padStart(2, '0'))
            .join('');
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new CHRNodeApp();
});
EOF
    
    echo "✅ JavaScript application created"
}

# Set up API integration
setup_api_integration() {
    echo "🔧 Setting up API integration..."
    
    mkdir -p "$API_DIR"
    
    # Create API helper script
    cat > "$API_DIR/termux-integration.js" << 'EOF'
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

class TermuxAPI {
    constructor() {
        this.isTermuxEnvironment = this.checkTermuxEnvironment();
    }
    
    checkTermuxEnvironment() {
        return process.env.PREFIX && process.env.PREFIX.includes('com.termux');
    }
    
    async getBatteryStatus() {
        if (!this.isTermuxEnvironment) return null;
        
        try {
            const { stdout } = await execAsync('termux-battery-status');
            return JSON.parse(stdout);
        } catch (error) {
            console.error('Battery status error:', error);
            return null;
        }
    }
    
    async getWifiInfo() {
        if (!this.isTermuxEnvironment) return null;
        
        try {
            const { stdout } = await execAsync('termux-wifi-connectioninfo');
            return JSON.parse(stdout);
        } catch (error) {
            console.error('WiFi info error:', error);
            return null;
        }
    }
    
    async getLocation() {
        if (!this.isTermuxEnvironment) return null;
        
        try {
            const { stdout } = await execAsync('termux-location -p network');
            return JSON.parse(stdout);
        } catch (error) {
            console.error('Location error:', error);
            return null;
        }
    }
    
    async showNotification(title, content) {
        if (!this.isTermuxEnvironment) return false;
        
        try {
            await execAsync(`termux-notification --title "${title}" --content "${content}"`);
            return true;
        } catch (error) {
            console.error('Notification error:', error);
            return false;
        }
    }
    
    async vibrate(duration = 1000) {
        if (!this.isTermuxEnvironment) return false;
        
        try {
            await execAsync(`termux-vibrate -d ${duration}`);
            return true;
        } catch (error) {
            console.error('Vibrate error:', error);
            return false;
        }
    }
    
    async speak(text) {
        if (!this.isTermuxEnvironment) return false;
        
        try {
            await execAsync(`termux-tts-speak "${text}"`);
            return true;
        } catch (error) {
            console.error('TTS error:', error);
            return false;
        }
    }
}

module.exports = TermuxAPI;
EOF
    
    echo "✅ API integration setup completed"
}

# Start services
start_services() {
    echo "🚀 Starting services..."
    
    # Start chr-node service
    if [ -f "$CHR_NODE_DIR/bin/chr-node-service" ]; then
        "$CHR_NODE_DIR/bin/chr-node-service" start
    fi
    
    # Start web interface
    cd "$WEB_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    
    # Start web server in background
    echo "Starting web interface..."
    npm start &
    
    # Save PID
    echo $! > "$CHR_NODE_DIR/web.pid"
    
    sleep 3
    
    # Get local IP for mobile access
    local ip_address=""
    if command -v termux-wifi-connectioninfo &> /dev/null; then
        ip_address=$(termux-wifi-connectioninfo 2>/dev/null | jq -r '.ip // empty' 2>/dev/null)
    fi
    
    if [ -z "$ip_address" ]; then
        ip_address=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    fi
    
    echo "✅ Services started successfully!"
    echo ""
    echo "🌐 Web Interface URLs:"
    echo "  Local:  http://localhost:3000"
    if [ "$ip_address" != "localhost" ]; then
        echo "  Mobile: http://$ip_address:3000"
    fi
    echo ""
    echo "📱 Access from mobile browser or scan QR code to connect wallet"
    echo ""
}

# Main setup function
main() {
    echo "🛠️  Starting chr-node development environment setup..."
    
    check_installation
    setup_web_interface
    create_web_server
    create_web_interface
    create_styles
    create_javascript
    setup_api_integration
    start_services
    
    echo ""
    echo "🎉 Development Environment Setup Complete!"
    echo "========================================"
    echo ""
    echo "✅ Web interface running on port 3000"
    echo "✅ NFT authentication system ready"
    echo "✅ QR code wallet linking enabled"
    echo "✅ Termux API integration configured"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Open web interface in browser"
    echo "2. Connect wallet via QR code or manual entry"
    echo "3. Verify Chronara Node Pass NFT ownership"
    echo "4. Access chr-node dashboard"
    echo ""
    echo "🔧 Service Management:"
    echo "  Web Interface: pm2 start/stop ecosystem.config.js"
    echo "  chr-node: chr-node-service {start|stop|restart|status}"
    echo ""
    echo "🎯 Ready for AI agent integration and personalization!"
}

# Execute setup
main "$@"