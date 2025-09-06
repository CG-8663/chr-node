#!/bin/bash

# Quick fix script for chr-node repository issues

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 chr-node Repository Fix Script${NC}"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -d "scripts" ]; then
    echo -e "${RED}❌ Please run this script from the chr-node root directory${NC}"
    exit 1
fi

# Check if gh CLI is available
if command -v gh &> /dev/null; then
    USE_GH_CLI=true
    echo -e "${GREEN}✅ GitHub CLI available${NC}"
else
    USE_GH_CLI=false
    echo -e "${YELLOW}⚠️  GitHub CLI not available - manual steps required${NC}"
fi

echo -e "${BLUE}🔍 Repository Status Check${NC}"
echo "=========================="

# Check current repository visibility
if [ "$USE_GH_CLI" = true ]; then
    echo "Checking repository visibility..."
    
    # Get repository info
    if REPO_INFO=$(gh repo view --json visibility,name,owner 2>/dev/null); then
        VISIBILITY=$(echo "$REPO_INFO" | jq -r '.visibility')
        REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name') 
        OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
        
        echo "Repository: $OWNER/$REPO_NAME"
        echo "Visibility: $VISIBILITY"
        
        if [ "$VISIBILITY" = "PRIVATE" ]; then
            echo -e "${RED}❌ Repository is PRIVATE - Termux installation will fail${NC}"
            echo ""
            echo -e "${YELLOW}🔓 Making repository PUBLIC...${NC}"
            
            if gh repo edit --visibility public; then
                echo -e "${GREEN}✅ Repository is now PUBLIC${NC}"
                echo "✅ Raw URLs will now work for Termux installation"
            else
                echo -e "${RED}❌ Failed to make repository public${NC}"
                echo "Please make it public manually:"
                echo "1. Go to https://github.com/$OWNER/$REPO_NAME/settings"
                echo "2. Scroll to 'Danger Zone'"
                echo "3. Click 'Change repository visibility'"
                echo "4. Select 'Make public'"
            fi
        else
            echo -e "${GREEN}✅ Repository is already PUBLIC${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not check repository status${NC}"
        echo "Make sure you're in a git repository with GitHub remote"
    fi
else
    echo -e "${YELLOW}Manual repository visibility check required:${NC}"
    echo "1. Visit your GitHub repository"
    echo "2. Go to Settings tab"
    echo "3. Scroll to 'Danger Zone'"
    echo "4. Ensure repository is PUBLIC (not private)"
    echo ""
    echo "Press Enter when repository is made public..."
    read -r
fi

echo ""
echo -e "${BLUE}🧪 Testing Installation Script Access${NC}"
echo "====================================="

# Get the current repository URL
if REMOTE_URL=$(git remote get-url origin 2>/dev/null); then
    # Extract owner and repo from URL
    if [[ $REMOTE_URL =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        OWNER=${BASH_REMATCH[1]}
        REPO=${BASH_REMATCH[2]}
        REPO=${REPO%.git}  # Remove .git if present
        
        RAW_URL="https://raw.githubusercontent.com/$OWNER/$REPO/main/scripts/termux-one-click-install.sh"
        
        echo "Testing installation script URL:"
        echo "$RAW_URL"
        echo ""
        
        # Test if the URL is accessible
        if curl -I "$RAW_URL" 2>/dev/null | grep -q "200 OK"; then
            echo -e "${GREEN}✅ Installation script is accessible${NC}"
            echo ""
            echo -e "${GREEN}🎉 SUCCESS! Users can now install with:${NC}"
            echo ""
            echo -e "${BLUE}curl -L $RAW_URL | bash${NC}"
            echo ""
        else
            echo -e "${RED}❌ Installation script is NOT accessible${NC}"
            echo ""
            echo "Possible issues:"
            echo "1. Repository is still private"
            echo "2. Script file doesn't exist on GitHub"
            echo "3. Branch name is not 'main'"
            echo ""
            echo "Try pushing the scripts to GitHub:"
            echo "git add scripts/"
            echo "git commit -m 'Add installation scripts'"
            echo "git push origin main"
        fi
    else
        echo -e "${RED}❌ Could not parse repository URL: $REMOTE_URL${NC}"
    fi
else
    echo -e "${RED}❌ No git remote found${NC}"
    echo "Add GitHub remote first:"
    echo "git remote add origin https://github.com/USER/REPO.git"
fi

echo ""
echo -e "${BLUE}🔍 File Check${NC}"
echo "=============="

# Check if required files exist
echo "Checking required files:"

if [ -f "scripts/termux-one-click-install.sh" ]; then
    echo "✅ scripts/termux-one-click-install.sh"
else
    echo "❌ scripts/termux-one-click-install.sh - MISSING!"
fi

if [ -f "scripts/deploy-to-github.sh" ]; then
    echo "✅ scripts/deploy-to-github.sh"
else
    echo "❌ scripts/deploy-to-github.sh - MISSING!"
fi

if [ -f "web-deployment/install-server.js" ]; then
    echo "✅ web-deployment/install-server.js"
else
    echo "❌ web-deployment/install-server.js - MISSING!"
fi

echo ""
echo -e "${BLUE}🚀 Quick Actions${NC}"
echo "================"

echo "1. 📤 Push current changes to GitHub:"
echo "   git add -A && git commit -m 'Update chr-node installation system' && git push"
echo ""

echo "2. 🧪 Test installation script locally:"
echo "   bash scripts/termux-one-click-install.sh"
echo ""

echo "3. 🌐 Test web server (if needed):"
echo "   cd web-deployment && npm install && npm start"
echo ""

echo "4. 📱 Test on Android with Termux:"
echo "   curl -L $RAW_URL | bash"
echo ""

# Offer to run deployment automatically
echo -e "${YELLOW}🤖 Auto-fix available actions:${NC}"
echo ""

if [ -f "scripts/deploy-to-github.sh" ]; then
    echo "Run deployment script? (y/N)"
    read -r run_deploy
    
    if [[ $run_deploy =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🚀 Running deployment script...${NC}"
        ./scripts/deploy-to-github.sh
    fi
fi

echo ""
echo -e "${GREEN}🎯 Summary${NC}"
echo "=========="
echo "For Termux installation to work:"
echo "1. ✅ Repository must be PUBLIC"
echo "2. ✅ Scripts must be pushed to GitHub"  
echo "3. ✅ Installation script must be accessible via raw URL"
echo ""

if [ -n "$RAW_URL" ]; then
    echo "Your installation URL:"
    echo -e "${BLUE}$RAW_URL${NC}"
    echo ""
    echo "Test it:"
    echo -e "${BLUE}curl -I $RAW_URL${NC}"
fi

echo -e "${GREEN}✨ Once fixed, users can install chr-node with a single command!${NC}"