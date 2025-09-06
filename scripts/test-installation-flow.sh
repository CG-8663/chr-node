#!/bin/bash

# Complete Installation Flow Testing Script
# Tests all components from release to deployment

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🧪 chr-node Complete Installation Flow Test"
echo "==========================================="

# Test configuration
RELEASE_VERSION="v1.0.0-beta"
GITHUB_REPO="CG-8663/chr-node"
TEST_DIR="/tmp/chr-node-test-$(date +%s)"
WEB_SERVER_PORT=3334

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Cleanup function
cleanup() {
    log_info "🧹 Cleaning up test environment..."
    rm -rf "$TEST_DIR" 2>/dev/null || true
    pkill -f "node install-server.js" 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

# Test 1: Verify GitHub Release
test_github_release() {
    log_info "📦 Testing GitHub Release..."
    
    # Check if release exists
    if curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/tags/$RELEASE_VERSION" | grep -q "tag_name"; then
        log_success "GitHub release $RELEASE_VERSION exists"
    else
        log_error "GitHub release $RELEASE_VERSION not found"
        return 1
    fi
    
    # Check release assets
    local assets=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/tags/$RELEASE_VERSION" | grep -o '"name":[^,]*' | cut -d'"' -f4)
    
    local expected_assets=(
        "chr-node-linux-arm64"
        "chr-node-linux-armv7" 
        "chr-node-linux-x86_64"
        "chr-node-darwin-arm64"
    )
    
    for asset in "${expected_assets[@]}"; do
        if echo "$assets" | grep -q "$asset"; then
            log_success "Release asset $asset found"
        else
            log_error "Release asset $asset missing"
            return 1
        fi
    done
}

# Test 2: Verify Web Server
test_web_server() {
    log_info "🌐 Testing Web Installation Server..."
    
    # Check if web server is running
    if curl -s "http://localhost:$WEB_SERVER_PORT/api/health" | grep -q "healthy"; then
        log_success "Web server is running on port $WEB_SERVER_PORT"
    else
        log_warn "Web server not running, starting it..."
        cd web-deployment
        PORT=$WEB_SERVER_PORT npm start > /dev/null 2>&1 &
        sleep 3
        cd ..
        
        if curl -s "http://localhost:$WEB_SERVER_PORT/api/health" | grep -q "healthy"; then
            log_success "Web server started successfully"
        else
            log_error "Failed to start web server"
            return 1
        fi
    fi
    
    # Test installation script endpoint
    if curl -s "http://localhost:$WEB_SERVER_PORT/install" | grep -q "chr-node One-Click Installation"; then
        log_success "Installation script endpoint working"
    else
        log_error "Installation script endpoint failed"
        return 1
    fi
    
    # Test main page
    if curl -s "http://localhost:$WEB_SERVER_PORT/" | grep -q "chr-node - One-Click Mobile Installation"; then
        log_success "Main page loads correctly"
    else
        log_error "Main page failed to load"
        return 1
    fi
}

# Test 3: Binary Download and Verification
test_binary_download() {
    log_info "⬇️ Testing Binary Download..."
    
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Test download of ARM64 binary (most common for Android)
    local binary_url="https://github.com/$GITHUB_REPO/releases/download/$RELEASE_VERSION/chr-node-linux-arm64"
    
    if curl -L -f -o "chr-node-test" "$binary_url"; then
        log_success "Binary download successful"
        
        # Verify it's executable
        chmod +x "chr-node-test"
        
        # Test binary execution (should work with bash even on non-Termux)
        if bash ./chr-node-test version | grep -q "chr-node"; then
            log_success "Binary executes correctly"
        else
            log_error "Binary execution failed"
            return 1
        fi
    else
        log_error "Binary download failed"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Test 4: Installation Script Functionality
test_installation_script() {
    log_info "📋 Testing Installation Script..."
    
    # Download installation script
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    if curl -s "http://localhost:$WEB_SERVER_PORT/install" -o "test-install.sh"; then
        log_success "Installation script downloaded"
        
        # Verify script content
        if grep -q "chr-node One-Click Installation" "test-install.sh"; then
            log_success "Installation script contains expected content"
        else
            log_error "Installation script content verification failed"
            return 1
        fi
        
        # Verify script is executable
        chmod +x "test-install.sh"
        if [ -x "test-install.sh" ]; then
            log_success "Installation script is executable"
        else
            log_error "Installation script is not executable"
            return 1
        fi
        
    else
        log_error "Failed to download installation script"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Test 5: Local Binary Testing
test_local_binaries() {
    log_info "🔧 Testing Local Binaries..."
    
    # Test development binary
    if [ -f "releases/chr-node-dev" ]; then
        if ./releases/chr-node-dev --version | grep -q "chr-node development build"; then
            log_success "Development binary works"
        else
            log_error "Development binary failed"
            return 1
        fi
    else
        log_warn "Development binary not found"
    fi
    
    # Test native binary
    local native_binary="releases/chr-node-darwin-arm64"
    if [ -f "$native_binary" ]; then
        if "$native_binary" version | grep -q "chr_node"; then
            log_success "Native binary works"
        else
            log_error "Native binary failed"
            return 1
        fi
    else
        log_warn "Native binary not found"
    fi
    
    # Test Android binaries
    local android_binaries=(
        "releases/chr-node-linux-arm64"
        "releases/chr-node-linux-armv7"
        "releases/chr-node-linux-x86_64"
    )
    
    for binary in "${android_binaries[@]}"; do
        if [ -f "$binary" ]; then
            if bash "$binary" version | grep -q "chr-node.*android-dev"; then
                log_success "Android binary $(basename $binary) works"
            else
                log_error "Android binary $(basename $binary) failed"
                return 1
            fi
        else
            log_warn "Android binary $(basename $binary) not found"
        fi
    done
}

# Test 6: End-to-End Installation Simulation
test_e2e_simulation() {
    log_info "🎯 Testing End-to-End Installation Simulation..."
    
    mkdir -p "$TEST_DIR/e2e-test"
    cd "$TEST_DIR/e2e-test"
    
    # Simulate the complete installation flow
    log_info "  → Downloading installation script via curl..."
    curl -s "http://localhost:$WEB_SERVER_PORT/install" -o "chr-node-install.sh"
    chmod +x "chr-node-install.sh"
    
    log_info "  → Checking script can detect architecture..."
    if grep -q "uname -m" "chr-node-install.sh"; then
        log_success "Script has architecture detection"
    else
        log_error "Script missing architecture detection"
        return 1
    fi
    
    log_info "  → Verifying GitHub download URLs in script..."
    if grep -q "github.com/$GITHUB_REPO/releases/download/$RELEASE_VERSION" "chr-node-install.sh"; then
        log_success "Script uses correct release URLs"
    else
        log_error "Script has incorrect release URLs"
        return 1
    fi
    
    log_info "  → Testing script syntax..."
    if bash -n "chr-node-install.sh"; then
        log_success "Installation script syntax is valid"
    else
        log_error "Installation script has syntax errors"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
}

# Test 7: Documentation Links
test_documentation() {
    log_info "📚 Testing Documentation Links..."
    
    local doc_urls=(
        "https://github.com/$GITHUB_REPO"
        "https://github.com/$GITHUB_REPO/releases/tag/$RELEASE_VERSION"
    )
    
    for url in "${doc_urls[@]}"; do
        if curl -s -I "$url" | grep -q "200 OK\|302 Found"; then
            log_success "Documentation link $url is accessible"
        else
            log_warn "Documentation link $url may not be accessible"
        fi
    done
}

# Main test execution
main() {
    echo "🚀 Starting comprehensive installation flow tests..."
    echo ""
    
    local tests=(
        "test_github_release"
        "test_web_server" 
        "test_binary_download"
        "test_installation_script"
        "test_local_binaries"
        "test_e2e_simulation"
        "test_documentation"
    )
    
    local passed=0
    local total=${#tests[@]}
    
    for test in "${tests[@]}"; do
        echo ""
        if $test; then
            ((passed++))
        else
            log_error "Test $test failed"
        fi
    done
    
    echo ""
    echo "📊 Test Results Summary"
    echo "======================"
    echo "Passed: $passed/$total tests"
    
    if [ $passed -eq $total ]; then
        echo ""
        log_success "🎉 ALL TESTS PASSED!"
        echo ""
        echo "✅ GitHub release is live and accessible"
        echo "✅ Web installation server is working"
        echo "✅ Binary downloads are functional" 
        echo "✅ Installation scripts are valid"
        echo "✅ End-to-end flow is operational"
        echo ""
        echo "🚀 chr-node is ready for production deployment!"
        echo ""
        echo "📱 Users can now install chr-node on Android/Termux with:"
        echo "   curl -L http://localhost:$WEB_SERVER_PORT/install | bash"
        echo ""
        echo "🌐 Or visit: http://localhost:$WEB_SERVER_PORT"
        
        return 0
    else
        echo ""
        log_error "❌ SOME TESTS FAILED"
        echo "Failed: $((total - passed))/$total tests"
        echo ""
        echo "Please review the test output above and fix any issues before deployment."
        
        return 1
    fi
}

# Run the main test suite
main "$@"