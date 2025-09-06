#!/bin/bash

# chr-node Private Repository Testing Script
# For testing installation while repository is still private

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🧪 chr-node Private Repository Testing${NC}"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "scripts/termux-one-click-install.sh" ]; then
    echo -e "${RED}❌ Please run this script from the chr-node root directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Testing Strategy for Private Repository${NC}"
echo "=========================================="
echo ""
echo "Since the repository is private, we'll test in these ways:"
echo "1. 📱 Direct script testing (local file)"
echo "2. 🌐 Web server testing (local hosting)"
echo "3. 🔐 Authenticated GitHub access testing"
echo "4. 🎯 Preparation for public release"
echo ""

# Test 1: Local script testing
echo -e "${BLUE}Test 1: Local Installation Script${NC}"
echo "================================="
echo ""

LOCAL_SCRIPT="scripts/termux-one-click-install.sh"

if [ -f "$LOCAL_SCRIPT" ]; then
    echo "✅ Installation script found: $LOCAL_SCRIPT"
    
    # Check script syntax
    if bash -n "$LOCAL_SCRIPT"; then
        echo "✅ Script syntax is valid"
    else
        echo "❌ Script has syntax errors"
        exit 1
    fi
    
    # Show script info
    SCRIPT_SIZE=$(wc -l < "$LOCAL_SCRIPT")
    echo "📊 Script size: $SCRIPT_SIZE lines"
    
    echo ""
    echo -e "${YELLOW}🧪 Test local script in Termux with:${NC}"
    echo "1. Copy script to Android device:"
    echo "   scp scripts/termux-one-click-install.sh android-device:/sdcard/"
    echo ""
    echo "2. In Termux, run:"
    echo "   cp /sdcard/termux-one-click-install.sh ."
    echo "   chmod +x termux-one-click-install.sh"
    echo "   ./termux-one-click-install.sh"
    
else
    echo "❌ Installation script not found!"
    exit 1
fi

echo ""
echo "─────────────────────────────────────────────"
echo ""

# Test 2: Web server testing  
echo -e "${BLUE}Test 2: Web Server Testing${NC}"
echo "=========================="
echo ""

if [ -f "web-deployment/install-server.js" ]; then
    echo "✅ Web server found"
    
    cd web-deployment
    
    # Check if dependencies are installed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing web server dependencies..."
        npm install
    fi
    
    echo ""
    echo -e "${YELLOW}🌐 Start web server for testing:${NC}"
    echo "   cd web-deployment"
    echo "   npm start"
    echo ""
    echo "Then test:"
    echo "   • Open http://localhost:3333"
    echo "   • Test QR code functionality"
    echo "   • Test copy command button"
    echo "   • Verify /install endpoint works"
    
    cd ..
else
    echo "❌ Web server files not found"
fi

echo ""
echo "─────────────────────────────────────────────"
echo ""

# Test 3: GitHub authentication testing
echo -e "${BLUE}Test 3: GitHub Authentication${NC}"
echo "=============================="
echo ""

if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI available"
    
    if gh auth status &> /dev/null; then
        echo "✅ GitHub CLI authenticated"
        
        # Test authenticated access to private repo
        if REPO_INFO=$(gh repo view --json name,owner,visibility 2>/dev/null); then
            REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
            OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
            VISIBILITY=$(echo "$REPO_INFO" | jq -r '.visibility')
            
            echo "✅ Repository access confirmed:"
            echo "   Repository: $OWNER/$REPO_NAME"
            echo "   Visibility: $VISIBILITY"
            
            # Test authenticated raw file access
            RAW_URL="https://raw.githubusercontent.com/$OWNER/$REPO_NAME/main/scripts/termux-one-click-install.sh"
            
            echo ""
            echo "🔐 Testing authenticated access to installation script..."
            
            # Create a temporary script that uses gh auth for access
            cat > test-auth-install.sh << EOF
#!/bin/bash
# Temporary authenticated installation script for private repo testing

echo "🔐 Downloading chr-node installation script with authentication..."

# Use gh to download the raw file with authentication
gh api repos/$OWNER/$REPO_NAME/contents/scripts/termux-one-click-install.sh \\
    --jq '.content' | base64 -d > chr-node-install-temp.sh

if [ -f "chr-node-install-temp.sh" ]; then
    echo "✅ Script downloaded successfully"
    chmod +x chr-node-install-temp.sh
    echo "🚀 Running installation..."
    ./chr-node-install-temp.sh
else
    echo "❌ Failed to download installation script"
    exit 1
fi
EOF
            
            chmod +x test-auth-install.sh
            
            echo "✅ Created authenticated installation script: test-auth-install.sh"
            echo ""
            echo -e "${YELLOW}🧪 Test authenticated installation in Termux:${NC}"
            echo "1. Copy test-auth-install.sh to Android device"
            echo "2. In Termux, run: gh auth login"  
            echo "3. Then run: ./test-auth-install.sh"
            
        else
            echo "❌ Could not access repository information"
        fi
    else
        echo "❌ GitHub CLI not authenticated"
        echo "Run: gh auth login"
    fi
else
    echo "❌ GitHub CLI not available"
    echo "Install: brew install gh"
fi

echo ""
echo "─────────────────────────────────────────────"
echo ""

# Test 4: Public release preparation
echo -e "${BLUE}Test 4: Public Release Preparation${NC}"
echo "=================================="
echo ""

echo "📋 Checklist for public release:"
echo ""

# Check all required files exist
FILES_TO_CHECK=(
    "scripts/termux-one-click-install.sh:Installation script"
    "scripts/deploy-to-github.sh:Deployment script"
    "web-deployment/install-server.js:Web server"
    "web-deployment/package.json:Web dependencies"
    "README.md:Repository README"
    "LICENSE:License file"
    "COMPLETE-SETUP-GUIDE.md:Setup guide"
    "TERMUX-INSTALLATION-GUIDE.md:Installation guide"
)

ALL_FILES_EXIST=true

for item in "${FILES_TO_CHECK[@]}"; do
    IFS=':' read -r file description <<< "$item"
    if [ -f "$file" ]; then
        echo "✅ $description ($file)"
    else
        echo "❌ $description ($file) - MISSING"
        ALL_FILES_EXIST=false
    fi
done

echo ""
if [ "$ALL_FILES_EXIST" = true ]; then
    echo -e "${GREEN}✅ All required files are present${NC}"
else
    echo -e "${RED}❌ Some required files are missing${NC}"
fi

echo ""
echo -e "${BLUE}🚀 When ready for public release:${NC}"
echo ""
echo "1. 🧪 Complete all private testing"
echo "2. 📝 Update version numbers and documentation"  
echo "3. 🔓 Make repository public:"
echo "   gh repo edit --visibility public"
echo ""
echo "4. 🏷️  Create public release:"
echo "   gh release create v1.0.0 --title 'chr-node v1.0.0' --notes 'Initial public release'"
echo ""
echo "5. 📱 Users can then install with:"
echo "   curl -L https://raw.githubusercontent.com/$OWNER/$REPO_NAME/main/scripts/termux-one-click-install.sh | bash"

echo ""
echo "─────────────────────────────────────────────"
echo ""

# Create testing URLs
echo -e "${BLUE}📋 Testing URLs (for when public):${NC}"
echo ""

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    if REPO_INFO=$(gh repo view --json name,owner 2>/dev/null); then
        REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
        OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
        
        echo "Public installation URL (when released):"
        echo "https://raw.githubusercontent.com/$OWNER/$REPO_NAME/main/scripts/termux-one-click-install.sh"
        echo ""
        echo "Repository URL:"
        echo "https://github.com/$OWNER/$REPO_NAME"
        echo ""
        echo "Releases URL:"
        echo "https://github.com/$OWNER/$REPO_NAME/releases"
    fi
fi

echo ""
echo -e "${GREEN}🎯 Summary${NC}"
echo "=========="
echo "✅ Keep repository private for now"
echo "✅ Test using local files and authenticated access"
echo "✅ Use web server for UI testing"
echo "✅ Make public when ready for user deployment"
echo ""
echo -e "${PURPLE}Happy testing! 🧪${NC}"