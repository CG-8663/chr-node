#!/bin/bash

# chr-node Website Deployment Script
# Prepares the chr-node website for public hosting with all installation files

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 chr-node Website Deployment${NC}"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -f "install-server.js" ]; then
    echo "❌ Please run this script from the web-deployment directory"
    exit 1
fi

echo -e "${BLUE}📦 Preparing public website assets...${NC}"

# Ensure public directory exists
mkdir -p public/{scripts,docs,assets}

# Copy latest installation script
echo "📋 Copying latest installation script..."
cp ../scripts/termux-one-click-install.sh public/scripts/

# Copy documentation
echo "📝 Copying documentation..."
cp ../README.md ../COMPLETE-SETUP-GUIDE.md ../TERMUX-INSTALLATION-GUIDE.md public/docs/ 2>/dev/null || true

# Copy test package files for alternative installation methods
echo "🧪 Copying test package files..."
cp -r ../chr-node-test-package/* public/scripts/ 2>/dev/null || true

# Create a website info file
cat > public/WEBSITE-INFO.txt << EOF
chr-node Public Website
======================

This website serves the chr-node installation system for remote Termux deployments.

Installation Commands:
- Main install: curl -L YOUR_DOMAIN/install | bash
- Direct script: curl -L YOUR_DOMAIN/scripts/termux-one-click-install.sh | bash

Available Endpoints:
- / - Main landing page with QR codes and installation instructions
- /install - One-click installation script
- /scripts/termux-one-click-install.sh - Direct script download
- /api/health - Health check endpoint
- /api/stats - Installation statistics

Files Included:
- Installation script ($(wc -l < public/scripts/termux-one-click-install.sh) lines)
- Complete documentation set
- Alternative installation methods
- Test utilities

Created: $(date)
Version: chr-node v1.0.0

Deployment Instructions:
1. Upload entire web-deployment directory to hosting service
2. Install dependencies: npm install
3. Start server: npm start (or node install-server.js)
4. Update domain references in HTML if needed
5. Test all endpoints before announcing

Repository remains private until stable.
Website provides public access to installation system.
EOF

echo "✅ Website assets prepared"

echo ""
echo -e "${BLUE}🧪 Testing website functionality...${NC}"

# Test if server is running
if curl -s http://localhost:3336/api/health > /dev/null; then
    echo "✅ Server is running and responding"
    
    # Test main endpoints
    if curl -I http://localhost:3336/install 2>/dev/null | grep -q "200 OK"; then
        echo "✅ /install endpoint working"
    else
        echo "❌ /install endpoint not responding"
    fi
    
    if curl -I http://localhost:3336/scripts/termux-one-click-install.sh 2>/dev/null | grep -q "200 OK"; then
        echo "✅ /scripts/termux-one-click-install.sh endpoint working"
    else
        echo "❌ Script endpoint not responding"
    fi
    
else
    echo "⚠️  Server not running. Start with: npm start"
fi

echo ""
echo -e "${YELLOW}📦 Website Package Summary:${NC}"
echo ""
echo "Public directory structure:"
find public -type f | head -20

TOTAL_FILES=$(find public -type f | wc -l)
TOTAL_SIZE=$(du -sh public | cut -f1)

echo ""
echo "Total files: $TOTAL_FILES"
echo "Total size: $TOTAL_SIZE"

echo ""
echo -e "${GREEN}🌐 Website Deployment Options:${NC}"
echo ""
echo "1. 🚀 Vercel (Recommended for Node.js):"
echo "   • npm install -g vercel"
echo "   • vercel --prod"
echo "   • Auto-scales, custom domains, HTTPS"
echo ""
echo "2. 🌊 Railway:"
echo "   • Connect GitHub repo to Railway"
echo "   • Auto-deploys on push"
echo "   • Built-in HTTPS and domains"
echo ""
echo "3. 🎯 DigitalOcean App Platform:"
echo "   • Upload as zip or connect repo"
echo "   • Managed hosting with scaling"
echo ""
echo "4. ☁️  Traditional VPS:"
echo "   • Upload files via SCP/SFTP"
echo "   • Install Node.js and npm"
echo "   • Use PM2 for process management"
echo "   • Configure nginx reverse proxy"
echo ""

echo -e "${BLUE}🧪 Testing Commands:${NC}"
echo ""
echo "Test locally:"
echo "  curl -L http://localhost:3336/install | head -20"
echo ""
echo "Test after deployment (replace YOUR_DOMAIN):"
echo "  curl -L https://YOUR_DOMAIN/install | bash"
echo ""

echo -e "${GREEN}✅ Website ready for deployment!${NC}"
echo ""
echo "Repository stays private for development."
echo "Website provides public chr-node installation access."
echo "Users can install chr-node on any Android device with Termux!"