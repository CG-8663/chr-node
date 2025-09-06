#!/data/data/com.termux/files/usr/bin/bash

# chr-node Termux Installation Script
# Automated setup for chr-node on Android via Termux

set -e

CHR_NODE_VERSION="v1.0.0"
CHR_NODE_DIR="$HOME/.chr-node"
CHR_NODE_CONFIG="$CHR_NODE_DIR/config"
CHR_NODE_LOGS="$CHR_NODE_DIR/logs"
CHR_NODE_WEB="$CHR_NODE_DIR/web"

echo "🚀 chr-node Termux Installation Script"
echo "====================================="
echo "Version: $CHR_NODE_VERSION"
echo "Install Path: $CHR_NODE_DIR"
echo "Timestamp: $(date)"
echo ""

# Check if running in Termux
check_termux_environment() {
    if [ ! -d "/data/data/com.termux" ]; then
        echo "❌ Error: This script must be run in Termux environment"
        echo "Please install Termux from F-Droid or Google Play Store"
        exit 1
    fi
    
    if [ "$PREFIX" != "/data/data/com.termux/files/usr" ]; then
        echo "❌ Error: Invalid Termux environment detected"
        exit 1
    fi
    
    echo "✅ Termux environment verified"
}

# Update package repositories
update_packages() {
    echo "📦 Updating package repositories..."
    
    pkg update -y
    pkg upgrade -y
    
    echo "✅ Package repositories updated"
}

# Install required dependencies
install_dependencies() {
    echo "🔧 Installing dependencies..."
    
    local packages=(
        "erlang"           # Elixir runtime
        "elixir"           # Elixir language
        "nodejs"           # Node.js for web interface
        "python"           # Python for scripts
        "git"              # Version control
        "curl"             # HTTP client
        "wget"             # File downloader
        "jq"               # JSON processor
        "sqlite"           # Database
        "openssl"          # Cryptography
        "zlib"             # Compression
        "termux-api"       # Termux API access
        "qrencode"         # QR code generation
        "zbar"             # QR code scanning
        "imagemagick"      # Image processing
        "ffmpeg"           # Audio/video processing
    )
    
    for package in "${packages[@]}"; do
        echo "Installing $package..."
        if ! pkg install -y "$package"; then
            echo "⚠️  Warning: Failed to install $package, continuing..."
        fi
    done
    
    # Install Node.js packages
    echo "Installing Node.js packages..."
    npm install -g pm2 express socket.io qrcode express-rate-limit helmet
    
    echo "✅ Dependencies installed"
}

# Create directory structure
create_directories() {
    echo "📁 Creating directory structure..."
    
    mkdir -p "$CHR_NODE_DIR"
    mkdir -p "$CHR_NODE_CONFIG"
    mkdir -p "$CHR_NODE_LOGS"
    mkdir -p "$CHR_NODE_WEB"
    mkdir -p "$CHR_NODE_DIR/data"
    mkdir -p "$CHR_NODE_DIR/tmp"
    mkdir -p "$CHR_NODE_DIR/keys"
    mkdir -p "$CHR_NODE_DIR/nft-cache"
    
    # Set secure permissions
    chmod 700 "$CHR_NODE_DIR/keys"
    chmod 755 "$CHR_NODE_DIR"
    
    echo "✅ Directory structure created"
}

# Download chr-node binary
download_chr_node() {
    echo "⬇️  Downloading chr-node binary..."
    
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
            echo "❌ Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    local download_url="https://github.com/CG-8663/chr-node/releases/download/$CHR_NODE_VERSION/$binary_name"
    local binary_path="$CHR_NODE_DIR/bin/chr-node"
    
    mkdir -p "$(dirname "$binary_path")"
    
    if curl -L -f -o "$binary_path" "$download_url"; then
        chmod +x "$binary_path"
        echo "✅ chr-node binary downloaded: $binary_path"
    else
        echo "⚠️  Failed to download binary, using local build if available..."
        # Fallback to local binary if available
        if [ -f "/sdcard/chr-node" ]; then
            cp "/sdcard/chr-node" "$binary_path"
            chmod +x "$binary_path"
            echo "✅ Using local chr-node binary"
        else
            echo "❌ No chr-node binary available"
            exit 1
        fi
    fi
}

# Generate configuration
generate_config() {
    echo "⚙️  Generating configuration..."
    
    local config_file="$CHR_NODE_CONFIG/chr-node.conf"
    local node_id=$(openssl rand -hex 32)
    local api_key=$(openssl rand -hex 16)
    
    cat > "$config_file" << EOF
# chr-node Configuration for Termux
[node]
id = "$node_id"
name = "chr-node-$(hostname)"
data_dir = "$CHR_NODE_DIR/data"
log_dir = "$CHR_NODE_LOGS"

[network]
listen_port = 8080
api_port = 3000
max_peers = 25
discovery_enabled = true

[termux]
api_enabled = true
optimization_level = "auto"
battery_optimization = true
data_conservation = true

[security]
api_key = "$api_key"
nft_verification = true
require_authentication = true

[web]
interface_port = 3000
enable_qr_scanner = true
enable_wallet_connect = true

[logging]
level = "info"
max_file_size = "10MB"
max_files = 5
EOF
    
    echo "✅ Configuration generated: $config_file"
    echo "📝 Node ID: $node_id"
    echo "🔑 API Key: $api_key"
}

# Create systemd service equivalent for Termux
create_service() {
    echo "🔄 Creating chr-node service..."
    
    local service_script="$CHR_NODE_DIR/bin/chr-node-service"
    
    cat > "$service_script" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

CHR_NODE_DIR="$HOME/.chr-node"
CHR_NODE_BIN="$CHR_NODE_DIR/bin/chr-node"
CHR_NODE_CONFIG="$CHR_NODE_DIR/config/chr-node.conf"
CHR_NODE_LOGS="$CHR_NODE_DIR/logs"

case "$1" in
    start)
        echo "Starting chr-node..."
        if [ -f "$CHR_NODE_DIR/chr-node.pid" ]; then
            echo "chr-node is already running (PID: $(cat $CHR_NODE_DIR/chr-node.pid))"
            exit 1
        fi
        
        nohup "$CHR_NODE_BIN" --config "$CHR_NODE_CONFIG" \
            > "$CHR_NODE_LOGS/chr-node.log" 2>&1 &
        
        echo $! > "$CHR_NODE_DIR/chr-node.pid"
        echo "chr-node started (PID: $!)"
        ;;
    
    stop)
        echo "Stopping chr-node..."
        if [ -f "$CHR_NODE_DIR/chr-node.pid" ]; then
            kill "$(cat $CHR_NODE_DIR/chr-node.pid)" 2>/dev/null || true
            rm -f "$CHR_NODE_DIR/chr-node.pid"
            echo "chr-node stopped"
        else
            echo "chr-node is not running"
        fi
        ;;
    
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    
    status)
        if [ -f "$CHR_NODE_DIR/chr-node.pid" ]; then
            pid=$(cat "$CHR_NODE_DIR/chr-node.pid")
            if kill -0 "$pid" 2>/dev/null; then
                echo "chr-node is running (PID: $pid)"
                exit 0
            else
                echo "chr-node is not running (stale PID file)"
                rm -f "$CHR_NODE_DIR/chr-node.pid"
                exit 1
            fi
        else
            echo "chr-node is not running"
            exit 1
        fi
        ;;
    
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$service_script"
    
    # Create convenient alias
    echo "alias chr-node-service='$service_script'" >> "$HOME/.bashrc"
    
    echo "✅ Service script created: $service_script"
}

# Set up Termux API permissions
setup_termux_api() {
    echo "🔐 Setting up Termux API permissions..."
    
    # Create API test script
    local api_test="$CHR_NODE_DIR/bin/test-termux-api"
    
    cat > "$api_test" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "🧪 Testing Termux API availability..."

apis=(
    "termux-battery-status:Battery Status"
    "termux-wifi-connectioninfo:WiFi Info"
    "termux-location:Location Services"
    "termux-sensor -l:Sensors"
    "termux-notification --help:Notifications"
    "termux-clipboard-get:Clipboard"
    "termux-volume music:Volume Control"
)

available_count=0
total_count=${#apis[@]}

for api_test in "${apis[@]}"; do
    IFS=':' read -r command description <<< "$api_test"
    
    if timeout 5s $command >/dev/null 2>&1; then
        echo "✅ $description"
        ((available_count++))
    else
        echo "❌ $description (not available)"
    fi
done

echo ""
echo "📊 API Summary: $available_count/$total_count APIs available"

if [ $available_count -lt 3 ]; then
    echo "⚠️  Warning: Limited API access detected"
    echo "Please ensure Termux:API is installed and permissions are granted"
fi
EOF
    
    chmod +x "$api_test"
    
    # Test API availability
    "$api_test"
    
    echo "✅ Termux API setup completed"
}

# Create desktop shortcuts
create_shortcuts() {
    echo "📱 Creating shortcuts..."
    
    # Create Termux widget scripts
    local widget_dir="$HOME/.shortcuts"
    mkdir -p "$widget_dir"
    
    # Start chr-node widget
    cat > "$widget_dir/chr-node-start" << EOF
#!/data/data/com.termux/files/usr/bin/bash
$CHR_NODE_DIR/bin/chr-node-service start
termux-notification --title "chr-node" --content "Node started successfully"
EOF
    
    # Stop chr-node widget
    cat > "$widget_dir/chr-node-stop" << EOF
#!/data/data/com.termux/files/usr/bin/bash
$CHR_NODE_DIR/bin/chr-node-service stop
termux-notification --title "chr-node" --content "Node stopped"
EOF
    
    # Status check widget
    cat > "$widget_dir/chr-node-status" << EOF
#!/data/data/com.termux/files/usr/bin/bash
if $CHR_NODE_DIR/bin/chr-node-service status > /dev/null 2>&1; then
    termux-notification --title "chr-node Status" --content "Node is running"
else
    termux-notification --title "chr-node Status" --content "Node is stopped"
fi
EOF
    
    chmod +x "$widget_dir"/*
    
    echo "✅ Shortcuts created in $widget_dir"
    echo "💡 Add Termux:Widget to access shortcuts from home screen"
}

# Final setup and verification
final_setup() {
    echo "🔍 Running final verification..."
    
    # Test binary execution
    if "$CHR_NODE_DIR/bin/chr-node" --version >/dev/null 2>&1; then
        echo "✅ chr-node binary is executable"
    else
        echo "⚠️  Warning: chr-node binary test failed"
    fi
    
    # Create startup script for easy access
    local startup_script="$CHR_NODE_DIR/setup-development.sh"
    cat > "$startup_script" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# chr-node Development Setup Script for Termux
# Run this script after installation to set up development environment

echo "🛠️  chr-node Development Environment Setup"
echo "=========================================="

CHR_NODE_DIR="$HOME/.chr-node"

# Start chr-node service
echo "Starting chr-node service..."
"$CHR_NODE_DIR/bin/chr-node-service" start

# Wait for service to initialize
sleep 3

# Start web interface
echo "Starting web interface..."
cd "$CHR_NODE_DIR/web"
npm start &

echo "✅ Development environment ready!"
echo ""
echo "🌐 Web Interface: http://localhost:3000"
echo "📱 Mobile Interface: http://$(termux-wifi-connectioninfo | jq -r '.ip'):3000"
echo "🔧 Service Control: chr-node-service {start|stop|restart|status}"
echo ""
echo "📋 Next Steps:"
echo "1. Open web interface in browser"
echo "2. Scan QR code or enter wallet address"
echo "3. Verify NFT ownership"
echo "4. Start using chr-node!"
EOF
    
    chmod +x "$startup_script"
    
    echo "✅ Setup script created: $startup_script"
}

# Main installation process
main() {
    echo "🚀 Starting chr-node installation..."
    
    check_termux_environment
    update_packages
    install_dependencies
    create_directories
    download_chr_node
    generate_config
    create_service
    setup_termux_api
    create_shortcuts
    final_setup
    
    echo ""
    echo "🎉 chr-node Installation Completed Successfully!"
    echo "=============================================="
    echo ""
    echo "📁 Installation Directory: $CHR_NODE_DIR"
    echo "⚙️  Configuration: $CHR_NODE_CONFIG/chr-node.conf"
    echo "📊 Logs: $CHR_NODE_LOGS"
    echo "🌐 Web Interface: $CHR_NODE_WEB"
    echo ""
    echo "🚀 Quick Start:"
    echo "  $CHR_NODE_DIR/setup-development.sh"
    echo ""
    echo "🔧 Service Management:"
    echo "  chr-node-service start    # Start the node"
    echo "  chr-node-service stop     # Stop the node" 
    echo "  chr-node-service status   # Check status"
    echo ""
    echo "📱 Shortcuts available in ~/.shortcuts/ for Termux:Widget"
    echo ""
    echo "🎯 Ready for NFT authentication and AI agent integration!"
}

# Execute installation
main "$@"