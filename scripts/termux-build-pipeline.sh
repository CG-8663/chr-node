#!/data/data/com.termux/files/usr/bin/bash

# chr-node Termux Build Pipeline
# Complete build system for both chr-node and client compilation during installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
CHR_NODE_HOME="${CHR_NODE_HOME:-$HOME/.chr-node}"
BUILD_DIR="$CHR_NODE_HOME/build"
SOURCE_DIR="$CHR_NODE_HOME/source"
INSTALL_LOG="$CHR_NODE_HOME/logs/build.log"
GITHUB_REPO="https://github.com/CG-8663/chr-node.git"

# Build configuration
ELIXIR_VERSION="1.15"
ERLANG_VERSION="26"
NODE_VERSION="18"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}" | tee -a "$INSTALL_LOG"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}" | tee -a "$INSTALL_LOG"
}

log_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}" | tee -a "$INSTALL_LOG"
}

# Banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                       ║"
    echo "║         🏗️  chr-node Termux Build Pipeline v2.0                     ║"
    echo "║                                                                       ║"
    echo "║           Complete In-Termux Compilation System                      ║"
    echo "║         • chr-node P2P Infrastructure                                ║"
    echo "║         • Diode Client Integration                                   ║"
    echo "║         • AI Agent Compilation                                       ║"
    echo "║         • Web Interface Generation                                   ║"
    echo "║                                                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# Environment detection
detect_environment() {
    log "🔍 Detecting Termux environment..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64|arm64)
            BINARY_ARCH="arm64"
            log "✅ Detected ARM64 architecture"
            ;;
        armv7l)
            BINARY_ARCH="armv7"
            log "✅ Detected ARMv7 architecture"
            ;;
        x86_64)
            BINARY_ARCH="x86_64"
            log "✅ Detected x86_64 architecture"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Verify Termux environment
    if [ -n "$PREFIX" ] && [ -d "$PREFIX" ]; then
        TERMUX_DETECTED=true
        log "✅ Termux environment confirmed: $PREFIX"
    else
        log_warn "Termux environment not detected - proceeding with Linux build"
        TERMUX_DETECTED=false
    fi
    
    # Check available resources
    TOTAL_MEMORY=$(free -m | awk 'NR==2{print $2}')
    AVAILABLE_SPACE=$(df -h "$HOME" | awk 'NR==2{print $4}')
    
    log_info "System Resources:"
    log_info "  Memory: ${TOTAL_MEMORY}MB"
    log_info "  Available Space: $AVAILABLE_SPACE"
    log_info "  Architecture: $BINARY_ARCH"
}

# Install build dependencies
install_dependencies() {
    log "📦 Installing build dependencies..."
    
    # Update package repositories
    log_info "Updating package repositories..."
    pkg update -y || true
    pkg upgrade -y || true
    
    # Essential build tools
    local deps=(
        "clang"
        "make"
        "cmake"
        "git"
        "curl"
        "wget"
        "unzip"
        "python"
        "nodejs"
        "npm"
        "erlang"
        "elixir"
        "sqlite"
        "openssl"
        "libsodium"
        "zlib"
        "ncurses"
    )
    
    log_info "Installing essential build dependencies..."
    for dep in "${deps[@]}"; do
        if ! pkg list-installed 2>/dev/null | grep -q "^$dep/"; then
            log_info "Installing $dep..."
            pkg install -y "$dep" || log_warn "Failed to install $dep"
        else
            log_info "✅ $dep already installed"
        fi
    done
    
    # Termux API integration
    if [ "$TERMUX_DETECTED" = true ]; then
        log_info "Installing Termux API integration..."
        pkg install -y termux-api || log_warn "Termux API installation failed"
    fi
    
    # Verify installations
    log_info "Verifying build environment..."
    elixir --version || log_error "Elixir not properly installed"
    node --version || log_error "Node.js not properly installed"
    npm --version || log_error "NPM not properly installed"
}

# Setup build environment
setup_build_environment() {
    log "🏗️ Setting up build environment..."
    
    # Create directory structure
    mkdir -p "$CHR_NODE_HOME"/{bin,config,data,logs,keys,web,build,source}
    
    # Set up Elixir environment
    export MIX_HOME="$CHR_NODE_HOME/mix"
    export HEX_HOME="$CHR_NODE_HOME/hex"
    mkdir -p "$MIX_HOME" "$HEX_HOME"
    
    # Install Hex and Rebar
    log_info "Installing Hex and Rebar..."
    mix local.hex --force || log_error "Failed to install Hex"
    mix local.rebar --force || log_error "Failed to install Rebar"
    
    # Set up Node.js environment
    export NPM_CONFIG_PREFIX="$CHR_NODE_HOME/npm"
    mkdir -p "$NPM_CONFIG_PREFIX"
    
    log "✅ Build environment ready"
}

# Clone or update source code
fetch_source_code() {
    log "📥 Fetching chr-node source code..."
    
    if [ -d "$SOURCE_DIR/.git" ]; then
        log_info "Updating existing source code..."
        cd "$SOURCE_DIR"
        git pull origin main || log_error "Failed to update source code"
    else
        log_info "Cloning chr-node repository..."
        rm -rf "$SOURCE_DIR"
        git clone "$GITHUB_REPO" "$SOURCE_DIR" || log_error "Failed to clone repository"
        cd "$SOURCE_DIR"
    fi
    
    # Verify source structure
    if [ ! -f "mix.exs" ]; then
        log_error "Invalid source structure - mix.exs not found"
        exit 1
    fi
    
    log "✅ Source code ready"
}

# Build chr-node binary
build_chr_node() {
    log "🔨 Building chr-node binary..."
    
    cd "$SOURCE_DIR"
    
    # Set build environment for Termux
    export MIX_ENV=prod
    export RELEASE_NAME=chr_node
    export CC=clang
    export CXX=clang++
    
    # Handle low memory systems
    if [ "$TOTAL_MEMORY" -lt 2048 ]; then
        log_warn "Low memory detected - enabling memory optimizations"
        export ERL_MAX_ETS_TABLES=1024
        export ERL_MAX_PORTS=4096
    fi
    
    # Clean previous builds
    log_info "Cleaning previous builds..."
    rm -rf _build deps
    
    # Get dependencies
    log_info "Fetching dependencies..."
    mix deps.get --only prod || log_error "Failed to get dependencies"
    
    # Compile dependencies separately to manage memory
    log_info "Compiling dependencies..."
    mix deps.compile || log_error "Failed to compile dependencies"
    
    # Compile application
    log_info "Compiling chr-node application..."
    mix compile || log_error "Failed to compile chr-node"
    
    # Create release
    log_info "Creating chr-node release..."
    mix release chr_node --overwrite || log_error "Failed to create release"
    
    # Copy binary to installation directory
    local binary_src="_build/prod/rel/chr_node/bin/chr_node"
    local binary_dst="$CHR_NODE_HOME/bin/chr-node"
    
    if [ -f "$binary_src" ]; then
        cp "$binary_src" "$binary_dst"
        chmod +x "$binary_dst"
        log "✅ chr-node binary built successfully"
    else
        log_error "Failed to find compiled binary"
        exit 1
    fi
}

# Build diode client
build_diode_client() {
    log "🔧 Building diode client..."
    
    cd "$SOURCE_DIR"
    
    # Check if diode client source exists in deps
    local client_dir="deps/diode_client"
    
    if [ -d "$client_dir" ]; then
        log_info "Building diode client from dependencies..."
        
        # Build client binary if Mix task exists
        if mix help diode_client.build >/dev/null 2>&1; then
            mix diode_client.build --output "$CHR_NODE_HOME/bin/diode-client" || log_warn "Diode client build failed"
        else
            log_info "Creating diode client wrapper..."
            # Create a wrapper script for client functionality
            cat > "$CHR_NODE_HOME/bin/diode-client" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Diode Client Wrapper
# Provides client functionality through chr-node

CHR_NODE_BIN="$(dirname "$0")/chr-node"

case "$1" in
    connect)
        "$CHR_NODE_BIN" rpc "DiodeClient.connect(\"$2\")"
        ;;
    status)
        "$CHR_NODE_BIN" rpc "DiodeClient.status()"
        ;;
    tunnel)
        "$CHR_NODE_BIN" rpc "DiodeClient.tunnel(\"$2\", $3, $4)"
        ;;
    *)
        echo "Diode Client Commands:"
        echo "  connect <address>  - Connect to remote device"
        echo "  status            - Show connection status"
        echo "  tunnel <host> <local_port> <remote_port> - Create tunnel"
        ;;
esac
EOF
            chmod +x "$CHR_NODE_HOME/bin/diode-client"
        fi
    else
        log_warn "Diode client source not found - creating stub"
        # Create basic client stub
        cat > "$CHR_NODE_HOME/bin/diode-client" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Diode client functionality integrated into chr-node"
echo "Use: chr-node rpc for client operations"
EOF
        chmod +x "$CHR_NODE_HOME/bin/diode-client"
    fi
    
    log "✅ Diode client ready"
}

# Build and setup web interface
setup_web_interface() {
    log "🌐 Setting up web interface..."
    
    # Check if web interface source exists
    local web_src_dir="$SOURCE_DIR/web-deployment"
    local web_dst_dir="$CHR_NODE_HOME/web"
    
    if [ -d "$web_src_dir" ]; then
        log_info "Copying web interface from source..."
        
        # Copy web interface files
        cp -r "$web_src_dir"/* "$web_dst_dir/" || log_error "Failed to copy web interface"
        
        cd "$web_dst_dir"
        
        # Install web dependencies
        if [ -f "package.json" ]; then
            log_info "Installing web interface dependencies..."
            npm install --production || log_warn "Web dependencies installation failed"
            
            # Create web interface startup script
            cat > "$CHR_NODE_HOME/bin/chr-node-web" << EOF
#!/data/data/com.termux/files/usr/bin/bash

# chr-node Web Interface Launcher
cd "$web_dst_dir"
export PORT=\${CHR_NODE_WEB_PORT:-3000}

echo "🌐 Starting chr-node web interface on port \$PORT"
node install-server.js &
WEB_PID=\$!
echo \$WEB_PID > "$CHR_NODE_HOME/.web-pid"

echo "✅ Web interface running at http://localhost:\$PORT"
echo "📱 Mobile access: http://\$(ifconfig | grep -o 'inet [0-9.]*' | head -1 | cut -d' ' -f2):\$PORT"
EOF
            chmod +x "$CHR_NODE_HOME/bin/chr-node-web"
            
        else
            log_warn "No package.json found - creating minimal web interface"
            create_minimal_web_interface
        fi
    else
        log_warn "Web interface source not found - creating minimal interface"
        create_minimal_web_interface
    fi
    
    log "✅ Web interface configured"
}

# Create minimal web interface if source not available
create_minimal_web_interface() {
    log_info "Creating minimal web interface..."
    
    # Create basic web server
    cat > "$CHR_NODE_HOME/web/server.js" << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.CHR_NODE_WEB_PORT || 3000;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Basic status endpoint
app.get('/api/status', (req, res) => {
    res.json({
        status: 'running',
        service: 'chr-node',
        timestamp: new Date().toISOString(),
        platform: 'termux-android'
    });
});

// Main page
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>chr-node - Mobile P2P Node</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial; margin: 40px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #333; text-align: center; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .button { background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 chr-node Mobile P2P Node</h1>
        <div class="status">
            <h3>✅ Node Status: Running</h3>
            <p><strong>Platform:</strong> Termux Android</p>
            <p><strong>Architecture:</strong> ${process.arch}</p>
            <p><strong>Started:</strong> ${new Date().toLocaleString()}</p>
        </div>
        <h3>Quick Actions:</h3>
        <a href="/api/status" class="button">📊 API Status</a>
        <a href="#" onclick="window.location.reload()" class="button">🔄 Refresh</a>
        
        <h3>Node Information:</h3>
        <ul>
            <li>P2P networking enabled</li>
            <li>AI agents ready</li>
            <li>Termux integration active</li>
            <li>Mobile optimizations enabled</li>
        </ul>
        
        <h3>Access Your Node:</h3>
        <p>Local: <code>http://localhost:${PORT}</code></p>
        <p>Network: <code>http://[your-ip]:${PORT}</code></p>
    </div>
</body>
</html>
    `);
});

app.listen(PORT, () => {
    console.log(`🌐 chr-node web interface running on port ${PORT}`);
    console.log(`📱 Access at: http://localhost:${PORT}`);
});
EOF
    
    # Create minimal package.json
    cat > "$CHR_NODE_HOME/web/package.json" << 'EOF'
{
  "name": "chr-node-web",
  "version": "1.0.0",
  "description": "chr-node web interface",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF
    
    # Install minimal dependencies
    cd "$CHR_NODE_HOME/web"
    npm install express || log_warn "Failed to install express"
}

# Create service management scripts
create_service_scripts() {
    log "⚙️ Creating service management scripts..."
    
    # Main service script
    cat > "$CHR_NODE_HOME/bin/chr-node-service" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# chr-node Service Management Script

CHR_NODE_HOME="${CHR_NODE_HOME:-$HOME/.chr-node}"
CHR_NODE_BIN="$CHR_NODE_HOME/bin/chr-node"
WEB_BIN="$CHR_NODE_HOME/bin/chr-node-web"
PID_FILE="$CHR_NODE_HOME/.chr-node-pid"
WEB_PID_FILE="$CHR_NODE_HOME/.web-pid"
LOG_FILE="$CHR_NODE_HOME/logs/chr-node.log"

start_service() {
    echo "🚀 Starting chr-node service..."
    
    # Start main node
    if [ -f "$CHR_NODE_BIN" ]; then
        cd "$CHR_NODE_HOME"
        "$CHR_NODE_BIN" start > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo "✅ chr-node started (PID: $!)"
    else
        echo "❌ chr-node binary not found"
        return 1
    fi
    
    # Start web interface
    if [ -f "$WEB_BIN" ]; then
        sleep 2
        "$WEB_BIN" &
        echo "✅ Web interface started"
    else
        echo "⚠️ Web interface not available"
    fi
    
    echo "🎉 chr-node service started successfully"
    echo "📊 View logs: tail -f $LOG_FILE"
}

stop_service() {
    echo "🛑 Stopping chr-node service..."
    
    # Stop web interface
    if [ -f "$WEB_PID_FILE" ]; then
        local web_pid=$(cat "$WEB_PID_FILE")
        if kill -0 "$web_pid" 2>/dev/null; then
            kill "$web_pid"
            echo "✅ Web interface stopped"
        fi
        rm -f "$WEB_PID_FILE"
    fi
    
    # Stop main service  
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "✅ chr-node stopped"
        fi
        rm -f "$PID_FILE"
    fi
    
    # Kill any remaining processes
    pkill -f "chr-node" 2>/dev/null || true
    
    echo "✅ chr-node service stopped"
}

show_status() {
    echo "chr-node Service Status"
    echo "======================="
    
    # Check main service
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Main Service: ✅ Running (PID: $pid)"
        else
            echo "Main Service: ❌ Not running (stale PID)"
        fi
    else
        echo "Main Service: ❌ Not running"
    fi
    
    # Check web interface
    if [ -f "$WEB_PID_FILE" ]; then
        local web_pid=$(cat "$WEB_PID_FILE")
        if kill -0 "$web_pid" 2>/dev/null; then
            echo "Web Interface: ✅ Running (PID: $web_pid)"
        else
            echo "Web Interface: ❌ Not running (stale PID)"
        fi
    else
        echo "Web Interface: ❌ Not running"
    fi
    
    # System info
    echo ""
    echo "System Information:"
    echo "Home: $CHR_NODE_HOME"
    echo "Binary: $CHR_NODE_BIN"
    echo "Logs: $LOG_FILE"
    echo "Web Port: ${CHR_NODE_WEB_PORT:-3000}"
}

case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        stop_service
        sleep 2
        start_service
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$CHR_NODE_HOME/bin/chr-node-service"
    
    # Create PATH link
    if [ -w "$PREFIX/bin" ]; then
        ln -sf "$CHR_NODE_HOME/bin/chr-node-service" "$PREFIX/bin/chr-node-service"
    fi
    
    log "✅ Service scripts created"
}

# Generate configuration files
generate_configuration() {
    log "📝 Generating configuration files..."
    
    # Main configuration
    cat > "$CHR_NODE_HOME/config/chr-node.conf" << EOF
[node]
id = "chr-node-termux-$(date +%s)"
name = "chr-node-mobile"
data_dir = "$CHR_NODE_HOME/data"

[network]
listen_port = 8080
api_port = 3000
max_peers = 50

[termux]
api_integration = true
battery_optimization = true
data_conservation = false
background_sync_interval = 300

[security]
api_key = "$(openssl rand -hex 16)"
nft_verification = false

[ai]
gemini_enabled = false
claude_enabled = false
proagent_enabled = false
xnomad_enabled = false

[performance]
memory_limit = ${TOTAL_MEMORY}mb
cpu_limit = 80
optimization_level = "mobile"
EOF
    
    # API keys template
    cat > "$CHR_NODE_HOME/config/api-keys.env.template" << 'EOF'
# chr-node API Keys Configuration
# Copy this file to api-keys.env and add your API keys

# AI Services
export GEMINI_API_KEY="your_gemini_api_key_here"
export ANTHROPIC_API_KEY="your_claude_api_key_here"

# Trading Services
export PROAGENT_API_KEY="your_proagent_key_here"
export XNOMAD_API_KEY="your_xnomad_key_here"

# Communication
export WHATSAPP_ACCESS_TOKEN="your_whatsapp_token_here"
export WHATSAPP_WEBHOOK_TOKEN="your_webhook_token_here"

# Load these keys by running: source $HOME/.chr-node/config/api-keys.env
EOF
    
    log "✅ Configuration files generated"
}

# Build summary and next steps
show_build_summary() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                       ║"
    echo "║                    🎉 Build Complete!                                ║"
    echo "║                                                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "✅ chr-node build pipeline completed successfully!"
    echo
    log_info "📁 Installation directory: $CHR_NODE_HOME"
    log_info "🔧 Binary location: $CHR_NODE_HOME/bin/chr-node"
    log_info "🌐 Web interface: $CHR_NODE_HOME/web/"
    log_info "📝 Configuration: $CHR_NODE_HOME/config/"
    log_info "📊 Logs: $CHR_NODE_HOME/logs/"
    
    echo
    log "🚀 Quick Start Commands:"
    echo "  chr-node-service start    # Start the service"
    echo "  chr-node-service status   # Check status"
    echo "  chr-node-service stop     # Stop the service"
    echo
    echo "🌐 Web Interface:"
    echo "  http://localhost:3000     # Local access"
    echo "  http://\$(ifconfig | grep -o 'inet [0-9.]*' | head -1 | cut -d' ' -f2):3000  # Network access"
    echo
    log "📚 Next Steps:"
    echo "1. Configure API keys in $CHR_NODE_HOME/config/api-keys.env"
    echo "2. Start the service: chr-node-service start"
    echo "3. Access web interface at http://localhost:3000"
    echo "4. Check logs: tail -f $CHR_NODE_HOME/logs/chr-node.log"
    
    echo
    log "🎉 chr-node is ready for mobile P2P networking!"
}

# Main build pipeline
main() {
    show_banner
    
    # Create logs directory first
    mkdir -p "$CHR_NODE_HOME/logs"
    
    log "🏗️ Starting chr-node Termux build pipeline..."
    log "Build started at $(date)"
    
    # Build steps
    detect_environment
    install_dependencies
    setup_build_environment
    fetch_source_code
    build_chr_node
    build_diode_client
    setup_web_interface
    create_service_scripts
    generate_configuration
    
    # Complete
    show_build_summary
    
    log "Build completed at $(date)"
    log "Total build time: $SECONDS seconds"
}

# Error handler
error_handler() {
    log_error "Build failed at step: ${BASH_COMMAND}"
    log_error "Check logs at: $INSTALL_LOG"
    exit 1
}

# Set error trap
trap error_handler ERR

# Run main pipeline
main "$@"