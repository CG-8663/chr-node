#!/bin/bash

# chr-node Multi-Platform Release Builder
# Builds binaries for all supported platforms: Linux ARM64, ARMv7, x86_64

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 chr-node Multi-Platform Release Builder"
echo "========================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf _build/prod
rm -rf releases/chr-node-*

# Check Elixir environment
echo "🔍 Checking build environment..."
if ! command -v mix &> /dev/null; then
    echo "❌ Elixir/Mix not found. Please install Elixir first."
    exit 1
fi

# Only check Docker for cross-platform builds
if [[ "$1" == "all" ]] && ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker for cross-compilation."
    echo "💡 Use './scripts/build-releases.sh native' for native builds without Docker"
    exit 1
fi

# Get version information
VERSION=$(git describe --tags 2>/dev/null || echo "v1.0.0")
echo "📦 Building chr-node $VERSION"

# Create releases directory
mkdir -p releases

# Function to build native binary
build_native() {
    local platform=$1
    local arch=$2
    local target_name="chr-node-$platform-$arch"
    
    echo "🔨 Building $target_name..."
    
    # Set environment for release build
    export MIX_ENV=prod
    export RELEASE_NAME=chr_node
    
    # Compile and create release
    mix deps.get --only prod
    mix compile
    mix release chr_node --overwrite
    
    # Copy binary to releases
    cp _build/prod/rel/chr_node/bin/chr_node "releases/$target_name"
    chmod +x "releases/$target_name"
    
    echo "✅ Built $target_name"
}

# Function to build ARM64 binary using Docker
build_arm64() {
    echo "🔨 Building chr-node-linux-arm64 using Docker..."
    
    # Create Dockerfile for ARM64 build
    cat > Dockerfile.arm64 << 'EOF'
FROM --platform=linux/arm64 elixir:1.15-alpine

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    openssl-dev \
    sqlite-dev

WORKDIR /app

# Copy source
COPY . .

# Build release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    MIX_ENV=prod mix deps.get && \
    MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release chr_node

# Copy binary to output
RUN cp _build/prod/rel/chr_node/bin/chr_node /chr-node-linux-arm64
EOF
    
    # Build ARM64 binary
    docker build --platform linux/arm64 -f Dockerfile.arm64 -t chr-node-arm64 .
    docker run --rm --platform linux/arm64 -v "$PWD/releases:/output" chr-node-arm64 cp /chr-node-linux-arm64 /output/
    
    # Cleanup
    rm Dockerfile.arm64
    docker rmi chr-node-arm64 2>/dev/null || true
    
    chmod +x releases/chr-node-linux-arm64
    echo "✅ Built chr-node-linux-arm64"
}

# Function to build ARMv7 binary using Docker
build_armv7() {
    echo "🔨 Building chr-node-linux-armv7 using Docker..."
    
    # Create Dockerfile for ARMv7 build
    cat > Dockerfile.armv7 << 'EOF'
FROM --platform=linux/arm/v7 elixir:1.15-alpine

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    openssl-dev \
    sqlite-dev

WORKDIR /app

# Copy source
COPY . .

# Build release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    MIX_ENV=prod mix deps.get && \
    MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release chr_node

# Copy binary to output
RUN cp _build/prod/rel/chr_node/bin/chr_node /chr-node-linux-armv7
EOF
    
    # Build ARMv7 binary
    docker build --platform linux/arm/v7 -f Dockerfile.armv7 -t chr-node-armv7 .
    docker run --rm --platform linux/arm/v7 -v "$PWD/releases:/output" chr-node-armv7 cp /chr-node-linux-armv7 /output/
    
    # Cleanup
    rm Dockerfile.armv7
    docker rmi chr-node-armv7 2>/dev/null || true
    
    chmod +x releases/chr-node-linux-armv7
    echo "✅ Built chr-node-linux-armv7"
}

# Function to build x86_64 binary using Docker
build_x86_64() {
    echo "🔨 Building chr-node-linux-x86_64 using Docker..."
    
    # Create Dockerfile for x86_64 build
    cat > Dockerfile.x86_64 << 'EOF'
FROM --platform=linux/amd64 elixir:1.15-alpine

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    openssl-dev \
    sqlite-dev

WORKDIR /app

# Copy source
COPY . .

# Build release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    MIX_ENV=prod mix deps.get && \
    MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release chr_node

# Copy binary to output
RUN cp _build/prod/rel/chr_node/bin/chr_node /chr-node-linux-x86_64
EOF
    
    # Build x86_64 binary
    docker build --platform linux/amd64 -f Dockerfile.x86_64 -t chr-node-x86_64 .
    docker run --rm --platform linux/amd64 -v "$PWD/releases:/output" chr-node-x86_64 cp /chr-node-linux-x86_64 /output/
    
    # Cleanup
    rm Dockerfile.x86_64
    docker rmi chr-node-x86_64 2>/dev/null || true
    
    chmod +x releases/chr-node-linux-x86_64
    echo "✅ Built chr-node-linux-x86_64"
}

# Function to create development/testing binary
build_dev_binary() {
    echo "🔨 Creating development binary..."
    
    # Create a mock binary for development testing
    cat > releases/chr-node-dev << 'EOF'
#!/bin/bash

# chr-node Development Mock Binary
# This is a development mock for testing installation flows

echo "[chr-node-dev] Development/Testing Binary"
echo "Version: $(date +%Y.%m.%d)-dev"
echo "Platform: $(uname -m)"
echo "OS: $(uname -s)"

case "$1" in
    --version)
        echo "chr-node development build $(date +%Y%m%d)"
        exit 0
        ;;
    --help)
        echo "chr-node - Chronara Network Lite Node"
        echo ""
        echo "Usage:"
        echo "  chr-node [options]"
        echo ""
        echo "Options:"
        echo "  --version    Show version information"
        echo "  --help       Show this help message"
        echo "  --config     Specify configuration file"
        echo "  --data-dir   Specify data directory"
        echo ""
        echo "This is a development mock binary for testing."
        exit 0
        ;;
    *)
        echo "Starting chr-node development mock..."
        echo "Configuration directory: $HOME/.chr-node"
        echo "Data directory: $HOME/.chr-node/data"
        echo "Logs directory: $HOME/.chr-node/logs"
        echo ""
        echo "Mock node running... (press Ctrl+C to stop)"
        
        # Create log entry
        LOG_DIR="$HOME/.chr-node/logs"
        mkdir -p "$LOG_DIR"
        echo "[$(date)] chr-node development mock started" >> "$LOG_DIR/chr-node.log"
        
        # Simulate running node
        while true; do
            echo "[$(date)] Mock node heartbeat - peers: 3, blocks: $(date +%s)"
            sleep 30
        done
        ;;
esac
EOF
    
    chmod +x releases/chr-node-dev
    echo "✅ Created development binary"
}

# Main build process
echo "🎯 Starting build process..."

# Build development binary first (for testing)
build_dev_binary

# Check what platforms to build
if [[ "$1" == "dev" ]]; then
    echo "🧪 Development build complete"
    echo "📁 Binary available at: releases/chr-node-dev"
    exit 0
fi

# For production builds, check if we want all platforms or specific ones
if [[ "$1" == "native" ]]; then
    # Build native binary only (current platform)
    CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    CURRENT_ARCH=$(uname -m)
    
    # Map architecture names
    case "$CURRENT_ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l) ARCH="armv7" ;;
        *) ARCH="$CURRENT_ARCH" ;;
    esac
    
    build_native "$CURRENT_OS" "$ARCH"
    
elif [[ "$1" == "all" ]] || [[ -z "$1" ]]; then
    # Build all platform binaries
    echo "🌍 Building for all platforms..."
    
    # Build cross-platform binaries using Docker
    build_arm64
    build_armv7  
    build_x86_64
    
    # Also build native if different from the above
    CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    if [[ "$CURRENT_OS" == "darwin" ]]; then
        build_native "darwin" "$(uname -m)"
    fi
    
else
    echo "❌ Unknown build target: $1"
    echo "Usage: $0 [dev|native|all]"
    echo "  dev    - Build development mock binary only"
    echo "  native - Build for current platform only"
    echo "  all    - Build for all platforms (default)"
    exit 1
fi

# Create checksums
echo "🔐 Creating checksums..."
cd releases
for binary in chr-node-*; do
    if [[ -f "$binary" ]]; then
        shasum -a 256 "$binary" > "$binary.sha256"
        echo "✅ Checksum created for $binary"
    fi
done
cd ..

# Show results
echo ""
echo "🎉 Build Complete!"
echo "=================="
echo "📁 Binaries created in releases/:"
ls -la releases/chr-node-*
echo ""
echo "📋 Version: $VERSION"
echo "🏗️  Build date: $(date)"
echo ""
echo "📦 Ready for deployment!"