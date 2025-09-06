#!/bin/bash

# Deploy chr-node to GitHub Repository
# This script helps you push all the necessary files to GitHub

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 chr-node GitHub Deployment Script${NC}"
echo "====================================="
echo ""

# Check if we're in the chr-node directory
if [ ! -f "mix.exs" ] || [ ! -d "scripts" ]; then
    echo -e "${RED}❌ Please run this script from the chr-node root directory${NC}"
    exit 1
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}📁 Initializing Git repository...${NC}"
    git init
    echo "✅ Git repository initialized"
fi

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Install it for easier repository creation:${NC}"
    echo "   macOS: brew install gh"
    echo "   Or visit: https://cli.github.com/"
    echo ""
    echo "You'll need to create the repository manually on GitHub."
    USE_GH_CLI=false
else
    echo -e "${GREEN}✅ GitHub CLI found${NC}"
    USE_GH_CLI=true
fi

# Get repository details
echo -e "${BLUE}📋 Repository Configuration${NC}"
echo "Current directory: $(pwd)"
echo ""

# Check if remote already exists
if git remote get-url origin &> /dev/null; then
    EXISTING_REMOTE=$(git remote get-url origin)
    echo -e "${YELLOW}📡 Existing remote found: $EXISTING_REMOTE${NC}"
    echo "Do you want to use this remote? (y/N)"
    read -r use_existing
    
    if [[ $use_existing =~ ^[Yy]$ ]]; then
        echo "Using existing remote..."
    else
        echo "Please remove existing remote first: git remote remove origin"
        exit 1
    fi
else
    echo "No existing remote found. We'll set one up."
    
    # Get repository details from user
    echo "Enter GitHub username/organization (default: CG-8663):"
    read -r github_user
    github_user=${github_user:-CG-8663}
    
    echo "Enter repository name (default: chr-node):"
    read -r repo_name
    repo_name=${repo_name:-chr-node}
    
    REPO_URL="https://github.com/$github_user/$repo_name.git"
    
    if [ "$USE_GH_CLI" = true ]; then
        echo -e "${BLUE}🏗️  Creating GitHub repository...${NC}"
        
        # Check if already logged in
        if ! gh auth status &> /dev/null; then
            echo "Please log in to GitHub CLI:"
            gh auth login
        fi
        
        # Create repository
        echo "Creating repository: $github_user/$repo_name"
        gh repo create "$github_user/$repo_name" --public --description "chr-node: Mobile P2P blockchain node for Chronara Network with AI integration"
        
        echo "✅ Repository created successfully"
    else
        echo -e "${YELLOW}📝 Manual repository creation required:${NC}"
        echo "1. Go to https://github.com/$github_user"
        echo "2. Click 'New repository'"
        echo "3. Name: $repo_name"
        echo "4. Description: chr-node: Mobile P2P blockchain node for Chronara Network with AI integration"
        echo "5. Make it public"
        echo "6. Don't initialize with README (we have files already)"
        echo ""
        echo "Press Enter when repository is created..."
        read -r
    fi
    
    # Add remote
    echo "Adding remote origin..."
    git remote add origin "$REPO_URL"
    echo "✅ Remote added: $REPO_URL"
fi

echo ""
echo -e "${BLUE}📦 Preparing files for deployment...${NC}"

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Build artifacts
_build/
deps/
*.beam
*.ez

# Environment variables
.env
.env.local
.env.*.local

# Logs
*.log
logs/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Temporary files
tmp/
temp/
.tmp/

# Test coverage
cover/

# Database
*.db
*.sqlite

# API Keys and secrets (use .env files)
config/api-keys.env
config/secrets.exs

# User-specific configuration
config/dev.local.exs
config/prod.local.exs

# Build outputs
priv/static/

# Elixir releases
rel/

# Mix tasks
.mix/
EOF
    echo "✅ .gitignore created"
fi

# Create README.md if it doesn't exist or is minimal
if [ ! -f "README.md" ] || [ $(wc -l < README.md) -lt 10 ]; then
    cat > README.md << 'EOF'
# chr-node

🌐 **Mobile P2P Blockchain Node for Chronara Network**

chr-node enables anyone with an Android device to participate in the Chronara Network, earn CHAI tokens, and access AI-powered trading and NFT insights.

## ✨ Features

- 📱 **One-Click Installation** on Android via Termux
- 🎨 **NFT-Based Authentication** with tiered access levels
- 🤖 **AI Agent Integration** (Gemini & Claude)
- 📊 **Trading Automation** with ProAgent integration
- 🎨 **NFT Intelligence** with xNomad.fun integration
- 💬 **WhatsApp Interface** for node management
- 🌍 **Emerging Markets Optimized** for low-resource devices
- 🔐 **Secure Remote Access** via Tailscale

## 🚀 Quick Start

### For Users (Android)

1. **Install Termux** from [F-Droid](https://f-droid.org/packages/com.termux/)
2. **Install Termux:API** from [F-Droid](https://f-droid.org/packages/com.termux.api/)
3. **Run one-click installer:**
   ```bash
   curl -L https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh | bash
   ```
4. **Access web interface:** `http://localhost:3000`
5. **Connect wallet** and verify your Chronara Node Pass NFT

### Service Management
```bash
chr-node-service start    # Start the node
chr-node-service stop     # Stop the node
chr-node-service status   # Check status
```

## 🏗️ Architecture

- **Elixir/OTP**: Fault-tolerant P2P networking core
- **Node.js**: Web interface and API server  
- **AI Integration**: Gemini (standard) & Claude (premium) APIs
- **Blockchain Integration**: Multi-chain support (Ethereum, Polygon, BNB, etc.)
- **Mobile Optimization**: Termux API integration for Android features

## 📱 Access Levels

| Level | NFT Requirement | Features |
|-------|----------------|----------|
| **Basic** | Token #1001+ | Node monitoring, basic AI |
| **Standard** | Token #101-1000 | Trading insights, WhatsApp |
| **Premium** | Token #1-100 | All features, advanced AI |

## 🛠️ Development

### Prerequisites
- Elixir 1.14+
- Erlang/OTP 25+
- Node.js 18+
- Android device with Termux (for mobile features)

### Local Development
```bash
# Clone repository
git clone https://github.com/CG-8663/chr-node.git
cd chr-node

# Install dependencies
mix deps.get
cd web-frontend && npm install

# Start development servers
mix run --no-halt
cd web-frontend && npm start
```

## 📚 Documentation

- [Complete Setup Guide](COMPLETE-SETUP-GUIDE.md)
- [Termux Installation Guide](TERMUX-INSTALLATION-GUIDE.md)
- [Mobile Deployment Strategy](docs/MOBILE-TERMUX-DEPLOYMENT-STRATEGY.md)
- [API Documentation](docs/API.md)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 💬 [Discord Community](https://discord.gg/chronara)
- 📧 Email: support@chronara.network
- 🐛 [Report Issues](https://github.com/CG-8663/chr-node/issues)
- 📖 [Documentation](https://docs.chronara.network)

## 🎯 Roadmap

- [x] Core P2P networking
- [x] Mobile Termux integration
- [x] NFT authentication system
- [x] AI agent integration
- [x] One-click installation
- [ ] iOS support (TestFlight)
- [ ] Desktop applications
- [ ] Hardware wallet integration
- [ ] Advanced trading features

---

**Join the future of mobile blockchain participation!** 🚀

*Built with ❤️ for emerging markets and the global crypto community.*
EOF
    echo "✅ README.md created"
fi

# Create LICENSE file
if [ ! -f "LICENSE" ]; then
    cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Chronara Network

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    echo "✅ LICENSE created"
fi

# Stage all files
echo -e "${BLUE}📤 Staging files...${NC}"

# Add files that exist
echo "Adding files to git..."

# Core files that should exist
if [ -f "mix.exs" ]; then git add mix.exs; echo "✅ mix.exs"; fi
if [ -f "README.md" ]; then git add README.md; echo "✅ README.md"; fi  
if [ -f "LICENSE" ]; then git add LICENSE; echo "✅ LICENSE"; fi
if [ -f ".gitignore" ]; then git add .gitignore; echo "✅ .gitignore"; fi
if [ -f "COMPLETE-SETUP-GUIDE.md" ]; then git add COMPLETE-SETUP-GUIDE.md; echo "✅ COMPLETE-SETUP-GUIDE.md"; fi
if [ -f "TERMUX-INSTALLATION-GUIDE.md" ]; then git add TERMUX-INSTALLATION-GUIDE.md; echo "✅ TERMUX-INSTALLATION-GUIDE.md"; fi
if [ -f "QUICK-DEPLOYMENT.md" ]; then git add QUICK-DEPLOYMENT.md; echo "✅ QUICK-DEPLOYMENT.md"; fi

# Directories that might exist
if [ -d "lib" ]; then git add lib/; echo "✅ lib/"; fi
if [ -d "config" ]; then git add config/; echo "✅ config/"; fi
if [ -d "scripts" ]; then git add scripts/; echo "✅ scripts/"; fi
if [ -d "docs" ]; then git add docs/; echo "✅ docs/"; fi
if [ -d "web-frontend" ]; then git add web-frontend/; echo "✅ web-frontend/"; fi
if [ -d "web-deployment" ]; then git add web-deployment/; echo "✅ web-deployment/"; fi

# Add any other files in the directory
git add *.md 2>/dev/null || true
git add *.exs 2>/dev/null || true

# Show status
echo ""
echo "Files to be committed:"
git status --porcelain

echo ""
echo -e "${YELLOW}📝 Commit message (or press Enter for default):${NC}"
read -r commit_message

if [ -z "$commit_message" ]; then
    commit_message="Initial chr-node release with mobile Termux integration

Features:
- One-click Termux installation for Android
- NFT-based authentication system  
- AI agent integration (Gemini & Claude)
- ProAgent trading automation
- xNomad.fun NFT intelligence
- WhatsApp interface for node management
- Emerging markets optimization
- Comprehensive web interface
- Remote access via Tailscale

Ready for mobile P2P blockchain participation! 🚀"
fi

# Commit changes
echo -e "${BLUE}💾 Committing changes...${NC}"
git commit -m "$commit_message"
echo "✅ Changes committed"

# Push to GitHub
echo ""
echo -e "${BLUE}📤 Pushing to GitHub...${NC}"
git branch -M main
git push -u origin main

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "==============================================="
echo ""
echo "Your chr-node repository is now live at:"
echo "🔗 https://github.com/$github_user/$repo_name"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo "1. 📦 Create a release for binaries:"
echo "   gh release create v1.0.0 --title 'chr-node v1.0.0' --notes 'Initial release'"
echo ""
echo "2. 🌐 Test the installation URL:"
echo "   https://raw.githubusercontent.com/$github_user/$repo_name/main/scripts/termux-one-click-install.sh"
echo ""
echo "3. 📱 Test on Android device:"
echo "   curl -L https://raw.githubusercontent.com/$github_user/$repo_name/main/scripts/termux-one-click-install.sh | bash"
echo ""
echo "4. 🎯 Update any hardcoded URLs in your code to point to this repository"
echo ""
echo "5. 🏷️ Consider setting up GitHub Actions for automated builds and releases"
echo ""

# Offer to create a release
if [ "$USE_GH_CLI" = true ]; then
    echo -e "${YELLOW}🏷️  Create an initial release now? (y/N)${NC}"
    read -r create_release
    
    if [[ $create_release =~ ^[Yy]$ ]]; then
        echo "Creating release v1.0.0..."
        
        gh release create v1.0.0 \
            --title "chr-node v1.0.0 - Mobile P2P Blockchain Node" \
            --notes "## 🌐 chr-node v1.0.0 - Initial Release

**The world's first one-click mobile blockchain node!**

### ✨ Features
- 📱 One-click installation on Android via Termux
- 🎨 NFT-based authentication with tiered access
- 🤖 AI agent integration (Gemini & Claude APIs)
- 📊 Trading automation with ProAgent
- 🎨 NFT intelligence with xNomad.fun
- 💬 WhatsApp interface for node management
- 🌍 Optimized for emerging markets
- 🔐 Secure remote access via Tailscale

### 🚀 Quick Install
\`\`\`bash
curl -L https://raw.githubusercontent.com/$github_user/$repo_name/main/scripts/termux-one-click-install.sh | bash
\`\`\`

### 📱 Requirements
- Android 7.0+ with Termux
- Chronara Node Pass NFT
- Internet connection

### 🆘 Support
- Discord: https://discord.gg/chronara
- Docs: https://docs.chronara.network
- Issues: https://github.com/$github_user/$repo_name/issues

**Join the future of mobile blockchain participation!** 🚀" \
            --prerelease

        echo "✅ Release v1.0.0 created successfully!"
        echo "🔗 https://github.com/$github_user/$repo_name/releases/tag/v1.0.0"
    fi
fi

echo ""
echo -e "${GREEN}🎊 All done! Your chr-node is ready for the world!${NC}"
echo ""
echo "Test the installation with:"
echo "curl -L https://raw.githubusercontent.com/$github_user/$repo_name/main/scripts/termux-one-click-install.sh | bash"