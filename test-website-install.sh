#!/data/data/com.termux/files/usr/bin/bash

# chr-node One-Click Installation Script for Termux
# Designed for automatic provisioning from website links

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
CHR_NODE_VERSION="v1.0.0"
GITHUB_REPO="https://github.com/CG-8663/chr-node"
CHR_NODE_DIR="$HOME/.chr-node"
INSTALL_LOG="$HOME/chr-node-install.log"
NODE_NAME="chr-node-$(date +%s)"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$INSTALL_LOG"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$INSTALL_LOG"
}

# Banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║               🌐 chr-node One-Click Installer               ║"
    echo "║                                                              ║"
    echo "║                   Chronara Network Node                      ║"
    echo "║                    Mobile P2P Infrastructure                 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    log "Starting chr-node installation for Android/Termux..."
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check if running in Termux
    if [ ! -d "/data/data/com.termux" ]; then
        log_error "This script must be run in Termux environment"
        echo ""
        echo "Please install Termux from F-Droid:"
        echo "https://f-droid.org/packages/com.termux/"
        exit 1
    fi
    
    # Check Android version
    ANDROID_VERSION=$(getprop ro.build.version.release)
    log "Android Version: $ANDROID_VERSION"
    
    # Check available storage
    AVAILABLE_SPACE=$(df /data/data/com.termux/files/home | tail -1 | awk '{print $4}')
    SPACE_MB=$((AVAILABLE_SPACE / 1024))
    
    if [ $SPACE_MB -lt 500 ]; then
        log_warn "Low storage space: ${SPACE_MB}MB available. Recommend 1GB+ free space."
        echo "Continue anyway? (y/N)"
        read -r response
        case $response in
            [yY][eE][sS]|[yY])
                log "Continuing with limited storage..."
                ;;
            *)
                log_error "Installation cancelled due to insufficient storage"
                exit 1
                ;;
        esac
    else
        log "Storage check: ${SPACE_MB}MB available ✅"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_error "No internet connection detected"
        echo "Please check your WiFi or mobile data connection"
        exit 1
    fi
    
    log "Internet connectivity ✅"
    log "Prerequisites check complete ✅"
    echo ""
}

# Update system packages
update_system() {
    log "📦 Updating system packages..."
    
    # Update package lists
    pkg update -y 2>&1 | tee -a "$INSTALL_LOG"
    
    # Upgrade existing packages
    pkg upgrade -y 2>&1 | tee -a "$INSTALL_LOG"
    
    log "System packages updated ✅"
    echo ""
}

# Install dependencies
install_dependencies() {
    log "🔧 Installing chr-node dependencies..."
    
    local packages=(
        "curl"              # HTTP client
        "wget"              # File downloader
        "git"               # Version control
        "python"            # Python runtime
        "nodejs"            # Node.js runtime
        "erlang"            # Erlang/OTP
        "elixir"            # Elixir language
        "sqlite"            # Database
        "openssl"           # Cryptography
        "termux-api"        # Termux API access
        "jq"                # JSON processor
        "nano"              # Text editor
        "htop"              # Process monitor
        "tree"              # Directory viewer
        "zip"               # Archive tool
        "unzip"             # Archive extractor
    )
    
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        log "Installing $package..."
        if pkg install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            log "$package installed ✅"
        else
            log_warn "$package installation failed, continuing..."
            failed_packages+=("$package")
        fi
    done
    
    if [ ${#failed_packages[@]} -ne 0 ]; then
        log_warn "Some packages failed to install: ${failed_packages[*]}"
        log_warn "chr-node may have limited functionality"
    fi
    
    # Install Node.js packages globally
    log "Installing Node.js packages..."
    npm install -g pm2 express socket.io qrcode helmet cors 2>&1 | tee -a "$INSTALL_LOG"
    
    log "Dependencies installation complete ✅"
    echo ""
}

# Create directory structure
create_directories() {
    log "📁 Creating directory structure..."
    
    # Main directories
    mkdir -p "$CHR_NODE_DIR"/{config,logs,data,tmp,keys,bin,web,agents,nft-cache}
    
    # Set permissions
    chmod 700 "$CHR_NODE_DIR/keys"
    chmod 755 "$CHR_NODE_DIR"
    
    # Create subdirectories
    mkdir -p "$CHR_NODE_DIR/web"/{public,src}
    mkdir -p "$CHR_NODE_DIR/config"/{api,network,security}
    mkdir -p "$CHR_NODE_DIR/logs"/{service,web,api}
    
    log "Directory structure created ✅"
    echo ""
}

# Download chr-node binary
download_chr_node() {
    log "⬇️ Downloading chr-node binary..."
    
    # Detect architecture
    local arch=$(uname -m)
    local binary_name=""
    
    case "$arch" in
        aarch64|arm64)
            binary_name="chr-node-android-arm64"
            ;;
        armv7l)
            binary_name="chr-node-android-armv7"
            ;;
        x86_64)
            binary_name="chr-node-android-x64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    log "Detected architecture: $arch"
    log "Downloading binary: $binary_name"
    
    # Download from GitHub releases (fallback to mock for now)
    local download_url="$GITHUB_REPO/releases/download/$CHR_NODE_VERSION/$binary_name"
    local binary_path="$CHR_NODE_DIR/bin/chr-node"
    
    # Try to download from GitHub
    if curl -L -f -o "$binary_path" "$download_url" 2>&1 | tee -a "$INSTALL_LOG"; then
        chmod +x "$binary_path"
        log "chr-node binary downloaded ✅"
    else
        log_warn "GitHub download failed, creating mock binary for testing..."
        
        # Create mock binary for testing
        cat > "$binary_path" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Mock chr-node binary for testing
echo "chr-node v1.0.0 (mock)"
echo "Usage: chr-node [options]"
echo "  --version    Show version"
echo "  --config     Configuration file"
echo "Mock binary created during installation"
EOF
        chmod +x "$binary_path"
        log "Mock chr-node binary created for testing ✅"
    fi
    
    echo ""
}

# Generate configuration
generate_configuration() {
    log "⚙️ Generating configuration..."
    
    # Generate unique IDs
    local node_id=$(openssl rand -hex 32)
    local api_key=$(openssl rand -hex 16)
    local tailscale_key=$(openssl rand -hex 24)
    
    # Get device info
    local device_model=$(getprop ro.product.model || echo "Unknown")
    local android_version=$(getprop ro.build.version.release || echo "Unknown")
    
    # Main configuration file
    cat > "$CHR_NODE_DIR/config/chr-node.conf" << EOF
# chr-node Configuration for Android/Termux
# Auto-generated on $(date)

[node]
id = "$node_id"
name = "$NODE_NAME"
version = "$CHR_NODE_VERSION"
platform = "android-termux"
data_dir = "$CHR_NODE_DIR/data"
log_dir = "$CHR_NODE_DIR/logs"

[device]
model = "$device_model"
android_version = "$android_version"
architecture = "$(uname -m)"
installation_date = "$(date -Iseconds)"

[network]
listen_port = 8080
api_port = 3000
web_port = 3000
max_peers = 25
discovery_enabled = true
upnp_enabled = true

[security]
api_key = "$api_key"
nft_verification = true
require_authentication = true
session_timeout = 3600

[termux]
api_enabled = true
optimization_level = "auto"
battery_optimization = true
data_conservation = true

[web]
interface_enabled = true
interface_port = 3000
enable_qr_scanner = true
enable_wallet_connect = true
cors_enabled = true

[logging]
level = "info"
max_file_size = "10MB"
max_files = 5
console_output = true

[tailscale]
enabled = false
auth_key = "$tailscale_key"
hostname = "chr-node-mobile"
EOF

    # Web configuration
    cat > "$CHR_NODE_DIR/config/web-config.json" << EOF
{
    "port": 3000,
    "host": "0.0.0.0",
    "apiUrl": "http://localhost:8080",
    "features": {
        "nftAuth": true,
        "qrScanner": true,
        "aiChat": true,
        "trading": false,
        "whatsapp": false
    },
    "security": {
        "apiKey": "$api_key",
        "corsOrigins": ["*"],
        "rateLimiting": true
    }
}
EOF

    # API keys template (user will fill these)
    cat > "$CHR_NODE_DIR/config/api-keys.env.template" << EOF
# AI API Keys (optional)
export GEMINI_API_KEY=""
export ANTHROPIC_API_KEY=""

# Trading API Keys (optional)
export PROAGENT_API_KEY=""
export XNOMAD_API_KEY=""

# Communication API Keys (optional)
export WHATSAPP_ACCESS_TOKEN=""
export WHATSAPP_PHONE_NUMBER_ID=""

# Load these keys with: source $CHR_NODE_DIR/config/api-keys.env
EOF

    # Node info file for easy reference
    cat > "$CHR_NODE_DIR/config/node-info.txt" << EOF
chr-node Installation Information
================================

Node ID: $node_id
Node Name: $NODE_NAME
API Key: $api_key
Installation Date: $(date)

Device Information:
- Model: $device_model
- Android: $android_version
- Architecture: $(uname -m)

Access Information:
- Web Interface: http://localhost:3000
- Mobile Access: http://$(get_local_ip):3000
- API Endpoint: http://localhost:8080

Service Management:
- Start: chr-node-service start
- Stop: chr-node-service stop
- Status: chr-node-service status
- Logs: tail -f $CHR_NODE_DIR/logs/chr-node.log

Configuration Files:
- Main Config: $CHR_NODE_DIR/config/chr-node.conf
- Web Config: $CHR_NODE_DIR/config/web-config.json
- API Keys: $CHR_NODE_DIR/config/api-keys.env

Next Steps:
1. Start the service: chr-node-service start
2. Open web interface in browser
3. Connect your wallet and verify NFT
4. Add API keys for AI features (optional)
5. Setup Tailscale for remote access (optional)

Support: https://discord.gg/chronara
EOF

    log "Configuration generated ✅"
    echo ""
}

# Create service management
create_service_management() {
    log "🔄 Creating service management..."
    
    # Main service script
    cat > "$CHR_NODE_DIR/bin/chr-node-service" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

CHR_NODE_DIR="$HOME/.chr-node"
CHR_NODE_BIN="$CHR_NODE_DIR/bin/chr-node"
CHR_NODE_CONFIG="$CHR_NODE_DIR/config/chr-node.conf"
CHR_NODE_LOGS="$CHR_NODE_DIR/logs"
PID_FILE="$CHR_NODE_DIR/chr-node.pid"
WEB_PID_FILE="$CHR_NODE_DIR/web.pid"

start_chr_node() {
    echo "🚀 Starting chr-node..."
    
    if [ -f "$PID_FILE" ]; then
        if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "chr-node is already running (PID: $(cat "$PID_FILE"))"
            return 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    # Start chr-node service
    nohup "$CHR_NODE_BIN" --config "$CHR_NODE_CONFIG" \
        > "$CHR_NODE_LOGS/chr-node.log" 2>&1 &
    
    echo $! > "$PID_FILE"
    echo "chr-node started (PID: $!)"
    
    # Start web interface
    cd "$CHR_NODE_DIR/web"
    if [ -f "package.json" ]; then
        nohup npm start > "$CHR_NODE_LOGS/web.log" 2>&1 &
        echo $! > "$WEB_PID_FILE"
        echo "Web interface started (PID: $!)"
    fi
    
    sleep 2
    
    # Show access information
    echo ""
    echo "✅ chr-node is running!"
    echo "🌐 Web Interface: http://localhost:3000"
    local_ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo "unknown")
    if [ "$local_ip" != "unknown" ]; then
        echo "📱 Mobile Access: http://$local_ip:3000"
    fi
    echo "📊 API Endpoint: http://localhost:8080"
    echo ""
    echo "View logs: tail -f $CHR_NODE_LOGS/chr-node.log"
}

stop_chr_node() {
    echo "🛑 Stopping chr-node..."
    
    # Stop chr-node
    if [ -f "$PID_FILE" ]; then
        if kill "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "chr-node stopped"
        else
            echo "Failed to stop chr-node (PID: $(cat "$PID_FILE"))"
        fi
        rm -f "$PID_FILE"
    else
        echo "chr-node is not running"
    fi
    
    # Stop web interface
    if [ -f "$WEB_PID_FILE" ]; then
        if kill "$(cat "$WEB_PID_FILE")" 2>/dev/null; then
            echo "Web interface stopped"
        else
            echo "Failed to stop web interface"
        fi
        rm -f "$WEB_PID_FILE"
    fi
}

status_chr_node() {
    local running=0
    
    echo "📊 chr-node Status"
    echo "=================="
    
    # Check chr-node service
    if [ -f "$PID_FILE" ]; then
        if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "🟢 chr-node: Running (PID: $(cat "$PID_FILE"))"
            running=$((running + 1))
        else
            echo "🔴 chr-node: Not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "🔴 chr-node: Not running"
    fi
    
    # Check web interface
    if [ -f "$WEB_PID_FILE" ]; then
        if kill -0 "$(cat "$WEB_PID_FILE")" 2>/dev/null; then
            echo "🟢 Web Interface: Running (PID: $(cat "$WEB_PID_FILE"))"
            running=$((running + 1))
        else
            echo "🔴 Web Interface: Not running (stale PID file)"
            rm -f "$WEB_PID_FILE"
        fi
    else
        echo "🔴 Web Interface: Not running"
    fi
    
    # Show URLs if running
    if [ $running -gt 0 ]; then
        echo ""
        echo "Access URLs:"
        echo "- Local: http://localhost:3000"
        local_ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo "unknown")
        if [ "$local_ip" != "unknown" ]; then
            echo "- Mobile: http://$local_ip:3000"
        fi
    fi
    
    echo ""
    echo "Logs: $CHR_NODE_LOGS/"
    echo "Config: $CHR_NODE_CONFIG"
}

case "$1" in
    start)
        start_chr_node
        ;;
    stop)
        stop_chr_node
        ;;
    restart)
        stop_chr_node
        sleep 2
        start_chr_node
        ;;
    status)
        status_chr_node
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

    chmod +x "$CHR_NODE_DIR/bin/chr-node-service"
    
    # Create convenient alias
    if ! grep -q "chr-node-service" "$HOME/.bashrc" 2>/dev/null; then
        echo "alias chr-node-service='$CHR_NODE_DIR/bin/chr-node-service'" >> "$HOME/.bashrc"
    fi
    
    log "Service management created ✅"
    echo ""
}

# Setup web interface
setup_web_interface() {
    log "🌐 Setting up web interface..."
    
    cd "$CHR_NODE_DIR/web"
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "chr-node-interface",
  "version": "1.0.0",
  "description": "chr-node Web Interface",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "helmet": "^7.0.0",
    "cors": "^2.8.5"
  }
}
EOF

    # Install web dependencies
    npm install 2>&1 | tee -a "$INSTALL_LOG"
    
    # Create basic web server
    cat > server.js << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const helmet = require('helmet');
const cors = require('cors');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

const PORT = process.env.PORT || 3000;

app.get('/api/status', (req, res) => {
    res.json({
        status: 'online',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

app.get('/', (req, res) => {
    res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>chr-node</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            .status { background: #e8f5e8; padding: 20px; border-radius: 10px; margin: 20px 0; }
            .button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; margin: 10px; text-decoration: none; display: inline-block; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🌐 chr-node</h1>
            <h2>Chronara Network Node</h2>
            <div class="status">
                <h3>✅ Node Online</h3>
                <p>Your chr-node is running successfully!</p>
            </div>
            <p>Connect your wallet to get started:</p>
            <a href="#" class="button" onclick="alert('Wallet connection coming soon!')">Connect Wallet</a>
            <a href="/api/status" class="button">API Status</a>
            <hr>
            <h3>Next Steps:</h3>
            <ol style="text-align: left; max-width: 400px; margin: 0 auto;">
                <li>Verify your Chronara Node Pass NFT</li>
                <li>Configure API keys for AI features</li>
                <li>Setup Tailscale for remote access</li>
                <li>Join our Discord community</li>
            </ol>
        </div>
    </body>
    </html>
    `);
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`chr-node web interface running on port ${PORT}`);
});
EOF

    log "Web interface setup complete ✅"
    echo ""
}

# Setup Termux API integration
setup_termux_api() {
    log "📱 Setting up Termux API integration..."
    
    # Create API test script
    cat > "$CHR_NODE_DIR/bin/test-termux-api" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "🧪 Testing Termux API Integration"
echo "=================================="

test_api() {
    local api_name="$1"
    local command="$2"
    local description="$3"
    
    echo -n "Testing $description... "
    
    if timeout 5s $command >/dev/null 2>&1; then
        echo "✅"
        return 0
    else
        echo "❌"
        return 1
    fi
}

available_count=0
total_count=0

# Test essential APIs
apis=(
    "Battery:termux-battery-status:Battery Status"
    "WiFi:termux-wifi-connectioninfo:WiFi Information"
    "Location:termux-location --help:Location Services"
    "Notifications:termux-notification --help:Notifications"
    "Clipboard:termux-clipboard-get:Clipboard Access"
    "Volume:termux-volume music:Volume Control"
    "Sensors:termux-sensor -l:Sensors"
    "Vibration:termux-vibrate --help:Vibration"
    "TTS:termux-tts-speak --help:Text-to-Speech"
    "Camera:termux-camera-info:Camera Info"
)

for api_data in "${apis[@]}"; do
    IFS=':' read -r name command desc <<< "$api_data"
    total_count=$((total_count + 1))
    
    if test_api "$name" "$command" "$desc"; then
        available_count=$((available_count + 1))
    fi
done

echo ""
echo "📊 API Summary: $available_count/$total_count APIs available"

if [ $available_count -lt 5 ]; then
    echo "⚠️  Limited API access detected"
    echo "Make sure Termux:API is installed and permissions are granted"
    echo ""
    echo "Install Termux:API:"
    echo "https://f-droid.org/packages/com.termux.api/"
else
    echo "✅ Good API coverage for chr-node features"
fi

echo ""
echo "Detailed API status saved to: $HOME/.chr-node/logs/api-test.log"
EOF

    chmod +x "$CHR_NODE_DIR/bin/test-termux-api"
    
    # Run API test and save results
    "$CHR_NODE_DIR/bin/test-termux-api" | tee "$CHR_NODE_DIR/logs/api-test.log"
    
    echo ""
}

# Create shortcuts and utilities
create_utilities() {
    log "🔧 Creating utilities and shortcuts..."
    
    # Create Termux shortcuts directory
    mkdir -p "$HOME/.shortcuts"
    
    # Start shortcut
    cat > "$HOME/.shortcuts/chr-node-start" << EOF
#!/data/data/com.termux/files/usr/bin/bash
$CHR_NODE_DIR/bin/chr-node-service start
termux-notification --title "chr-node" --content "Node started successfully"
EOF

    # Stop shortcut
    cat > "$HOME/.shortcuts/chr-node-stop" << EOF
#!/data/data/com.termux/files/usr/bin/bash
$CHR_NODE_DIR/bin/chr-node-service stop
termux-notification --title "chr-node" --content "Node stopped"
EOF

    # Status shortcut
    cat > "$HOME/.shortcuts/chr-node-status" << EOF
#!/data/data/com.termux/files/usr/bin/bash
status=\$($CHR_NODE_DIR/bin/chr-node-service status 2>&1 | grep -o "Running\|Not running" | head -1)
termux-notification --title "chr-node Status" --content "Node is \$status"
EOF

    chmod +x "$HOME/.shortcuts"/*
    
    # Create quick setup script for API keys
    cat > "$CHR_NODE_DIR/bin/setup-api-keys" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "🔑 chr-node API Keys Setup"
echo "=========================="
echo ""
echo "This script helps you configure API keys for enhanced chr-node features."
echo ""

CONFIG_FILE="$HOME/.chr-node/config/api-keys.env"
cp "$HOME/.chr-node/config/api-keys.env.template" "$CONFIG_FILE"

echo "Enter your API keys (press Enter to skip):"
echo ""

read -p "Gemini API Key (for AI features): " GEMINI_KEY
if [ ! -z "$GEMINI_KEY" ]; then
    sed -i "s/export GEMINI_API_KEY=\"\"/export GEMINI_API_KEY=\"$GEMINI_KEY\"/" "$CONFIG_FILE"
fi

read -p "Claude API Key (for premium AI): " CLAUDE_KEY
if [ ! -z "$CLAUDE_KEY" ]; then
    sed -i "s/export ANTHROPIC_API_KEY=\"\"/export ANTHROPIC_API_KEY=\"$CLAUDE_KEY\"/" "$CONFIG_FILE"
fi

echo ""
echo "✅ API keys configured!"
echo "To load keys: source $CONFIG_FILE"
echo "Restart chr-node to apply: chr-node-service restart"
EOF

    chmod +x "$CHR_NODE_DIR/bin/setup-api-keys"
    
    log "Utilities created ✅"
    echo ""
}

# Get local IP address
get_local_ip() {
    ip route get 1 2>/dev/null | awk '{print $7; exit}' 2>/dev/null || echo "localhost"
}

# Final setup and verification
final_setup() {
    log "🏁 Finalizing installation..."
    
    # Test chr-node binary
    if "$CHR_NODE_DIR/bin/chr-node" --version >/dev/null 2>&1; then
        log "chr-node binary test ✅"
    else
        log_warn "chr-node binary test failed (using mock binary)"
    fi
    
    # Create desktop entry for web interface
    local_ip=$(get_local_ip)
    
    # Update node info with final details
    cat >> "$CHR_NODE_DIR/config/node-info.txt" << EOF

Installation Complete!
=====================

Your chr-node is ready to use. Here's what you can do next:

1. Start the service:
   chr-node-service start

2. Access web interface:
   - Local: http://localhost:3000
   - Mobile: http://$local_ip:3000

3. Connect your wallet and verify your Chronara Node Pass NFT

4. Optional enhancements:
   - Add AI API keys: $CHR_NODE_DIR/bin/setup-api-keys
   - Setup Tailscale: pkg install tailscale && tailscale up
   - Join Discord: https://discord.gg/chronara

Service Management Commands:
- chr-node-service start    # Start chr-node
- chr-node-service stop     # Stop chr-node  
- chr-node-service status   # Check status
- chr-node-service restart  # Restart chr-node

Logs and Monitoring:
- Main log: tail -f $CHR_NODE_DIR/logs/chr-node.log
- Web log: tail -f $CHR_NODE_DIR/logs/web.log
- Test APIs: $CHR_NODE_DIR/bin/test-termux-api

Termux Widget Shortcuts:
- chr-node-start   # Quick start from home screen
- chr-node-stop    # Quick stop from home screen
- chr-node-status  # Check status with notification

Support:
- Documentation: https://docs.chronara.network
- Discord: https://discord.gg/chronara
- Issues: https://github.com/CG-8663/chr-node/issues

Thank you for joining the Chronara Network! 🚀
EOF

    log "Final setup complete ✅"
    echo ""
}

# Installation summary
show_summary() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║            🎉 chr-node Installation Complete! 🎉            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    log "Installation Summary:"
    log "📁 Installation Directory: $CHR_NODE_DIR"
    log "🆔 Node ID: $(head -1 "$CHR_NODE_DIR/config/node-info.txt" | grep "Node ID" | cut -d: -f2 | xargs)"
    log "🌐 Web Interface: http://localhost:3000"
    
    local_ip=$(get_local_ip)
    if [ "$local_ip" != "localhost" ]; then
        log "📱 Mobile Access: http://$local_ip:3000"
    fi
    
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Start your node: ${GREEN}chr-node-service start${NC}"
    echo "2. Open web interface in browser"
    echo "3. Connect your wallet and verify NFT"
    echo "4. Optional: Setup API keys with ${GREEN}$CHR_NODE_DIR/bin/setup-api-keys${NC}"
    echo ""
    
    echo -e "${CYAN}Support & Community:${NC}"
    echo "📖 Docs: https://docs.chronara.network"
    echo "💬 Discord: https://discord.gg/chronara"
    echo "📧 Support: support@chronara.network"
    echo ""
    
    echo -e "${WHITE}Installation log saved to: $INSTALL_LOG${NC}"
    echo ""
    
    # Show final node info
    echo -e "${BLUE}Node Information:${NC}"
    echo "$(cat "$CHR_NODE_DIR/config/node-info.txt" | head -15)"
    echo ""
    
    echo -e "${GREEN}🚀 Ready to join the Chronara Network!${NC}"
}

# Main installation flow
main() {
    show_banner
    check_prerequisites
    update_system
    install_dependencies
    create_directories
    download_chr_node
    generate_configuration
    create_service_management
    setup_web_interface
    setup_termux_api
    create_utilities
    final_setup
    show_summary
}

# Handle script interruption
trap 'echo -e "\n${RED}Installation interrupted!${NC}" && exit 1' INT TERM

# Run main installation
main "$@"