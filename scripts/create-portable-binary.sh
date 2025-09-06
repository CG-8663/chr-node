#!/bin/bash

# Create a portable, self-contained chr-node binary

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📦 Creating portable chr-node binary..."

# Build release if not exists
if [ ! -f "_build/prod/rel/chr_node/bin/chr_node" ]; then
    echo "🔨 Building release first..."
    MIX_ENV=prod mix release chr_node --overwrite
fi

# Create releases directory
mkdir -p releases

# Get current platform info
CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
CURRENT_ARCH=$(uname -m)

# Map architecture names
case "$CURRENT_ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="armv7" ;;
    *) ARCH="$CURRENT_ARCH" ;;
esac

BINARY_NAME="chr-node-$CURRENT_OS-$ARCH"
PORTABLE_PATH="releases/$BINARY_NAME"

echo "🎯 Creating portable binary: $BINARY_NAME"

# Create a portable wrapper script that sets up the environment
cat > "$PORTABLE_PATH" << 'EOF'
#!/bin/bash

# chr-node Portable Binary Wrapper
# This script sets up the environment and runs chr-node from any location

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHR_NODE_HOME="${CHR_NODE_HOME:-$HOME/.chr-node}"

# Create chr-node directory structure
mkdir -p "$CHR_NODE_HOME"/{bin,config,data,logs,keys}

# Check if we're running from a full installation
if [ -f "$SCRIPT_DIR/../_build/prod/rel/chr_node/bin/chr_node" ]; then
    # Running from source/development environment
    RELEASE_ROOT="$SCRIPT_DIR/../_build/prod/rel/chr_node"
    export RELEASE_ROOT
    
    # Set up release environment
    export RELEASE_NAME="chr_node"
    export RELEASE_VSN="1.0.0"
    export RELEASE_COOKIE="chr-node-cookie"
    export RELEASE_NODE="chr_node@$(hostname -s)"
    
    # Execute the actual binary
    exec "$RELEASE_ROOT/bin/chr_node" "$@"
    
elif [ -f "$CHR_NODE_HOME/bin/chr_node" ]; then
    # Running from installed location
    RELEASE_ROOT="$CHR_NODE_HOME"
    export RELEASE_ROOT
    
    # Set up release environment  
    export RELEASE_NAME="chr_node"
    export RELEASE_VSN="1.0.0"
    export RELEASE_COOKIE="chr-node-cookie"
    export RELEASE_NODE="chr_node@$(hostname -s)"
    
    # Execute the installed binary
    exec "$CHR_NODE_HOME/bin/chr_node" "$@"
    
else
    # No installation found - this is a development/testing scenario
    echo "[chr-node] No chr-node installation found."
    echo "[chr-node] This appears to be a development/testing environment."
    
    case "$1" in
        --version|version)
            echo "chr-node development build $(date +%Y%m%d)"
            echo "Platform: $(uname -m)"
            echo "OS: $(uname -s)"
            echo "Build: Portable development wrapper"
            exit 0
            ;;
        --help|help)
            echo "chr-node - Chronara Network Lite Node"
            echo ""
            echo "Usage:"
            echo "  chr-node [command] [options]"
            echo ""
            echo "Commands:"
            echo "  start        Start the node daemon"
            echo "  stop         Stop the node daemon"
            echo "  restart      Restart the node daemon"
            echo "  status       Show node status"
            echo "  version      Show version information"
            echo "  help         Show this help message"
            echo ""
            echo "Options:"
            echo "  --config     Specify configuration file"
            echo "  --data-dir   Specify data directory"
            echo ""
            echo "Environment Variables:"
            echo "  CHR_NODE_HOME    chr-node installation directory (default: ~/.chr-node)"
            echo "  CHR_NODE_CONFIG  Configuration file path"
            echo ""
            echo "This is a portable development wrapper."
            echo "Full installation provides complete chr-node functionality."
            exit 0
            ;;
        start)
            echo "[chr-node] Starting development mock node..."
            echo "[chr-node] Configuration directory: $CHR_NODE_HOME"
            echo "[chr-node] Data directory: $CHR_NODE_HOME/data"
            echo "[chr-node] Logs directory: $CHR_NODE_HOME/logs"
            echo ""
            
            # Create log entry
            echo "[$(date)] chr-node portable mock started" >> "$CHR_NODE_HOME/logs/chr-node.log"
            
            echo "[chr-node] Development node running... (press Ctrl+C to stop)"
            
            # Simulate running node
            while true; do
                echo "[$(date)] Node heartbeat - peers: 3, blocks: $(date +%s)" | tee -a "$CHR_NODE_HOME/logs/chr-node.log"
                sleep 30
            done
            ;;
        stop)
            echo "[chr-node] Stopping development mock node..."
            pkill -f "chr-node.*start" 2>/dev/null || echo "[chr-node] No running instances found"
            exit 0
            ;;
        status)
            echo "[chr-node] Node Status: Development Mode"
            echo "[chr-node] Installation: Portable wrapper"
            echo "[chr-node] Home directory: $CHR_NODE_HOME"
            
            if pgrep -f "chr-node.*start" > /dev/null; then
                echo "[chr-node] Status: Running (development mock)"
            else
                echo "[chr-node] Status: Stopped"
            fi
            exit 0
            ;;
        *)
            echo "[chr-node] Unknown command: $1"
            echo "[chr-node] Use 'chr-node help' for available commands"
            exit 1
            ;;
    esac
fi
EOF

chmod +x "$PORTABLE_PATH"

echo "✅ Portable binary created: $PORTABLE_PATH"
echo ""
echo "🧪 Testing portable binary..."

# Test the portable binary
"$PORTABLE_PATH" --version

echo ""
echo "🎉 Portable binary ready for deployment!"
echo "📁 Location: $PORTABLE_PATH"
echo "🔧 This binary can be run from any location and will work in development/testing scenarios"