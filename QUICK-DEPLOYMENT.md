# chr-node Quick Deployment Guide

## 🚀 Deploy to GitHub (Required for Termux Install)

### Step 1: Deploy Scripts to GitHub
```bash
# From the chr-node directory:
cd /Volumes/BACKUPDISK/nodefirstgen/chr-node

# Run the deployment script:
./scripts/deploy-to-github.sh
```

This will:
- ✅ Initialize Git repository
- ✅ Create/update GitHub repository  
- ✅ Generate README.md and LICENSE
- ✅ Push all scripts and code
- ✅ Create initial release (v1.0.0)
- ✅ Make installation script publicly available

### Step 2: Test Web Server (Optional)
```bash
# Navigate to web deployment directory
cd web-deployment

# Install dependencies
npm install

# Start the server
npm start
```

Server will run at: `http://localhost:3333`

### Step 3: Test QR Code Fix
1. Open `http://localhost:3333` in browser
2. Click "Show QR Code" button  
3. Verify QR code appears correctly
4. QR code should contain the curl command

### Step 4: Test Installation Script
```bash
# Test the GitHub-hosted script:
curl -L https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh

# This should download and display the installation script
```

## 🧪 Testing Checklist

### Web Server Tests
- [ ] Landing page loads (`http://localhost:3333`)
- [ ] "Copy Command" button works
- [ ] "Show QR Code" button displays QR code correctly  
- [ ] QR code contains full curl command
- [ ] Installation script downloads (`/install` endpoint)
- [ ] API endpoints respond (`/api/health`, `/api/stats`)

### GitHub Integration Tests  
- [ ] Repository created successfully
- [ ] All scripts are accessible via raw.githubusercontent.com
- [ ] Installation script can be downloaded directly
- [ ] README.md displays correctly on GitHub
- [ ] Release created (if using GitHub CLI)

### Termux Installation Tests (Android Required)
- [ ] Script downloads in Termux
- [ ] All dependencies install correctly
- [ ] chr-node service starts
- [ ] Web interface accessible  
- [ ] Termux APIs tested
- [ ] Service management commands work

## 🔧 Troubleshooting

### QR Code Not Showing
✅ **Fixed**: Updated `showQR()` function to properly create canvas element and handle errors

### Installation Script Not Found (404)
- Ensure GitHub repository is public
- Check the raw URL format: `https://raw.githubusercontent.com/[user]/[repo]/main/scripts/termux-one-click-install.sh`
- Verify file was pushed to GitHub correctly

### Web Server Port Conflicts
```bash
# If port 3333 is in use, specify different port:
PORT=4444 npm start
```

### GitHub Authentication Issues  
```bash
# Setup GitHub CLI authentication:
gh auth login

# Or create repository manually and add remote:
git remote add origin https://github.com/CG-8663/chr-node.git
```

## 📋 Final URLs After Deployment

After successful deployment, these URLs will be available:

### GitHub Repository
- **Main repo**: `https://github.com/CG-8663/chr-node`
- **Installation script**: `https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh`
- **Releases**: `https://github.com/CG-8663/chr-node/releases`

### Installation Commands  
```bash
# One-click install for users:
curl -L https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh | bash

# Download only:
curl -L -o chr-node-install.sh https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh
chmod +x chr-node-install.sh
./chr-node-install.sh
```

### Web Server (if deployed)
- **Landing page**: `http://your-server.com:3333`
- **Install endpoint**: `http://your-server.com:3333/install`  
- **API health**: `http://your-server.com:3333/api/health`

## 🎯 Next Steps

1. **Test on real Android device** with Termux
2. **Verify all Termux APIs** work correctly
3. **Test NFT authentication** flow  
4. **Validate web interface** responsiveness
5. **Check AI integration** with API keys
6. **Test WhatsApp interface** (if configured)
7. **Verify Tailscale setup** for remote access

## 🌐 Public Deployment Options

### Option A: GitHub Pages (Simple)
- Host the web interface on GitHub Pages
- Users copy/paste installation command
- No server maintenance required

### Option B: Cloud Hosting (Full Features)  
Deploy web server to:
- **Vercel**: Easy Node.js hosting
- **Railway**: Simple deployment with custom domains  
- **DigitalOcean**: VPS with full control
- **AWS/GCP**: Enterprise-grade hosting

### Option C: Your Mac Studio (Development)
- Run web server locally for testing
- Use ngrok for temporary public access
- Perfect for development and testing

---

**Your chr-node is now ready for global deployment! 🚀**

Users can install with a single command, and you have full control over the network.