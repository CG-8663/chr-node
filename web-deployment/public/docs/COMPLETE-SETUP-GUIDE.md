# chr-node Complete Setup Guide

## Step-by-Step First Node Setup

### Phase 1: Manual First Node (Your Testing)

#### Prerequisites Setup
1. **Android Device** (or Android emulator on Mac/PC)
2. **Install Termux from F-Droid**
   ```
   https://f-droid.org/packages/com.termux/
   ```
3. **Install Termux:API**
   ```
   https://f-droid.org/packages/com.termux.api/
   ```

#### Step 1: Basic Termux Setup
```bash
# Open Termux and run these commands:

# Grant storage permissions
termux-setup-storage

# Update packages
pkg update && pkg upgrade -y

# Install basic tools
pkg install curl wget git nano -y
```

#### Step 2: Download and Run chr-node Installation
```bash
# Download the one-click installer
curl -L -o chr-node-install.sh "https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh"

# Make it executable
chmod +x chr-node-install.sh

# Run the installation (takes 5-10 minutes)
./chr-node-install.sh
```

#### Step 3: Verify Installation
```bash
# Check service status
chr-node-service status

# Test web interface
curl http://localhost:3000/api/status

# Test Termux API integration
$HOME/.chr-node/bin/test-termux-api

# View node information
cat $HOME/.chr-node/config/node-info.txt
```

#### Step 4: Start Your Node
```bash
# Start chr-node service
chr-node-service start

# Check it's running
chr-node-service status

# View logs
tail -f $HOME/.chr-node/logs/chr-node.log
```

#### Step 5: Access Web Interface
1. **Get your device IP:**
   ```bash
   ip route get 1 | awk '{print $7; exit}'
   ```

2. **Open browser and navigate to:**
   ```
   http://[your-device-ip]:3000
   ```

3. **Connect wallet and verify NFT ownership**

#### Step 6: Setup Tailscale (Optional)
```bash
# Install Tailscale
pkg install tailscale -y

# Start daemon
tailscaled --tun=userspace-networking &

# Authenticate (follow the URL it shows)
tailscale up --hostname=chr-node-mobile

# Get Tailscale IP
tailscale ip -4
```

---

## Phase 2: Automatic Provisioning System

### Setting Up the Installation Website

#### Option A: Simple GitHub Pages Deployment

1. **Create a simple landing page** that serves the installation script:
   ```html
   <!-- index.html -->
   <!DOCTYPE html>
   <html>
   <head>
       <title>chr-node One-Click Install</title>
       <style>/* Your styling */</style>
   </head>
   <body>
       <h1>🌐 chr-node One-Click Install</h1>
       <button onclick="copyInstallCommand()">📱 Install chr-node</button>
       <script>
           function copyInstallCommand() {
               const command = 'curl -L https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux-one-click-install.sh | bash';
               navigator.clipboard.writeText(command);
               alert('Installation command copied! Paste in Termux.');
           }
       </script>
   </body>
   </html>
   ```

2. **Deploy to GitHub Pages** or any static hosting

#### Option B: Full Installation Server (Recommended)

1. **Deploy the installation server:**
   ```bash
   # On your server (can be same Mac Studio)
   cd /path/to/chr-node/web-deployment
   
   # Install dependencies
   npm install express cors qrcode
   
   # Start the server
   node install-server.js
   ```

2. **Server provides:**
   - Landing page with one-click install
   - QR codes for mobile installation
   - Installation script serving
   - Analytics and tracking
   - Responsive mobile-friendly interface

### User Installation Flow

#### Method 1: Direct Link
1. User visits: `https://chr-node.network/install`
2. Downloads installation script automatically
3. Opens Termux and runs the script

#### Method 2: Copy Command
1. User visits: `https://chr-node.network`
2. Clicks "Copy Command" button
3. Opens Termux, pastes and runs

#### Method 3: QR Code
1. User visits website on desktop/laptop
2. Clicks "Show QR Code"
3. Scans QR with Android device
4. Opens Termux and runs command

### The Installation Process (Automated)

When user runs the installation command, it:

1. **Downloads the full installer script**
2. **Checks prerequisites** (Android, Termux, storage, internet)
3. **Updates system packages** (apt update/upgrade)
4. **Installs dependencies** (Elixir, Node.js, Python, etc.)
5. **Downloads chr-node binary** (architecture-specific)
6. **Creates directory structure** (~/.chr-node/...)
7. **Generates configuration** (unique node ID, API keys, etc.)
8. **Sets up web interface** (Node.js server on port 3000)
9. **Creates service management** (start/stop/restart commands)
10. **Tests Termux API integration** (all 21+ APIs)
11. **Creates shortcuts** (Termux widgets for home screen)
12. **Provides final instructions** (how to connect wallet, etc.)

### Post-Installation Automatic Features

#### Service Management
```bash
# These commands are automatically available:
chr-node-service start    # Start the node
chr-node-service stop     # Stop the node
chr-node-service restart  # Restart the node
chr-node-service status   # Check status
```

#### Web Interface Access
- **Local:** `http://localhost:3000`
- **Mobile Network:** `http://[device-ip]:3000`
- **Tailscale:** `http://[tailscale-ip]:3000`

#### Termux Widget Shortcuts
- **chr-node-start** - Quick start from Android home screen
- **chr-node-stop** - Quick stop from Android home screen
- **chr-node-status** - Status check with notification

#### API Keys Setup (Optional)
```bash
# Run this for AI features:
$HOME/.chr-node/bin/setup-api-keys

# Follow prompts to add:
# - Gemini API Key (for AI assistant)
# - Claude API Key (for premium AI)
# - WhatsApp API keys (for messaging)
```

---

## Phase 3: Remote Access with Tailscale

### Tailscale Integration

#### Automatic Setup During Installation
The installer can optionally configure Tailscale:

1. **During installation**, user is prompted:
   ```
   Setup Tailscale for remote access? (Y/n)
   ```

2. **If yes**, installer:
   - Installs Tailscale package
   - Starts daemon in userspace mode
   - Shows authentication URL
   - Configures hostname as `chr-node-[timestamp]`

3. **User authenticates** via browser on another device

4. **Installer completes** with Tailscale IP shown

#### Manual Setup After Installation
```bash
# Install Tailscale
pkg install tailscale -y

# Start daemon
tailscaled --tun=userspace-networking &

# Authenticate
tailscale up --hostname=chr-node-mobile

# Get IP for remote access
tailscale ip -4
```

### Remote Access Workflow

#### For You (Node Operator)
1. **Install Tailscale** on your Mac Studio
2. **Join same Tailnet** as your mobile nodes
3. **Access any node** via: `http://[tailscale-ip]:3000`
4. **SSH access** (if enabled): `ssh u0_a123@[tailscale-ip] -p 8022`

#### Security Features
- **Private network** - Nodes not visible on public internet
- **Encrypted tunnels** - All traffic encrypted end-to-end
- **Access controls** - You control who can access what
- **Audit logs** - Track all access and changes

---

## Phase 4: User Onboarding Website

### Complete Website Structure

```
chr-node.network/
├── /                    # Landing page with install options
├── /install             # Direct installation script download
├── /docs               # Documentation
├── /support            # Help and troubleshooting
├── /api/stats          # Installation statistics
└── /api/health         # Service health check
```

### Landing Page Features

1. **Responsive Design** - Works on desktop and mobile
2. **Real-time Stats** - Shows install count, active nodes
3. **Multiple Install Methods:**
   - Direct download
   - Copy command
   - QR code scanning
4. **Requirements Checker** - Validates device compatibility
5. **Progress Tracking** - Shows installation progress
6. **Support Integration** - Links to Discord, docs, support

### Installation Analytics

Track important metrics:
- **Installation attempts** vs **successful installs**
- **Device types and architectures**
- **Geographic distribution**
- **Time to complete installation**
- **Common failure points**

---

## Phase 5: Scaling for Multiple Users

### GitHub Release Strategy

#### Binary Distribution
1. **Build binaries** for all architectures:
   - `chr-node-android-arm64`
   - `chr-node-android-armv7`
   - `chr-node-android-x64`

2. **Create GitHub releases** with:
   - Version tags (v1.0.0, v1.0.1, etc.)
   - Release notes
   - Binaries attached
   - Installation instructions

3. **Update installer** to download from latest release

#### Automated Building
```yaml
# .github/workflows/build-release.yml
name: Build and Release
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        arch: [arm64, armv7, x64]
    steps:
      - uses: actions/checkout@v3
      - name: Build for ${{ matrix.arch }}
        run: |
          # Build chr-node for target architecture
          # Upload to release
```

### Content Delivery Network (CDN)

For faster global distribution:
1. **Use GitHub Releases** as primary distribution
2. **Mirror to CDN** for faster downloads
3. **Regional optimization** - serve from closest location
4. **Fallback strategies** if primary source fails

### Support Infrastructure

#### Documentation Site
- **Installation guides** for different scenarios
- **Troubleshooting guides** for common issues
- **API documentation** for developers
- **Video tutorials** for visual learners

#### Community Support
- **Discord server** for real-time help
- **GitHub Issues** for bug reports
- **Community wiki** for user-contributed content
- **FAQ section** for common questions

---

## Testing Your Setup

### Manual Testing Checklist

#### Basic Installation
- [ ] Download and run installer
- [ ] Verify all dependencies installed
- [ ] Check service starts correctly
- [ ] Confirm web interface accessible
- [ ] Test Termux API integration
- [ ] Validate configuration generated

#### Web Interface Testing
- [ ] Open web interface in browser
- [ ] Test QR code generation
- [ ] Verify wallet connection flow
- [ ] Check NFT verification process
- [ ] Test mobile responsive design
- [ ] Validate API endpoints respond

#### Service Management
- [ ] Test start/stop/restart commands
- [ ] Verify service status reporting
- [ ] Check log file creation
- [ ] Test automatic restart on crash
- [ ] Validate PID file management

#### Tailscale Integration
- [ ] Install and configure Tailscale
- [ ] Test remote access via Tailscale IP
- [ ] Verify encrypted connection
- [ ] Check hostname resolution
- [ ] Test access controls

### Automated Testing

Create test scripts for continuous validation:

```bash
#!/bin/bash
# test-installation.sh

echo "🧪 Testing chr-node installation..."

# Test service
if chr-node-service status | grep -q "Running"; then
    echo "✅ Service is running"
else
    echo "❌ Service not running"
    exit 1
fi

# Test web interface
if curl -s http://localhost:3000/api/status | grep -q "online"; then
    echo "✅ Web interface responding"
else
    echo "❌ Web interface not responding"
    exit 1
fi

# Test Termux APIs
api_count=$($HOME/.chr-node/bin/test-termux-api | grep -o "[0-9]\+/[0-9]\+" | cut -d'/' -f1)
if [ "$api_count" -ge 5 ]; then
    echo "✅ Sufficient APIs available ($api_count)"
else
    echo "⚠️  Limited API access ($api_count)"
fi

echo "🎉 Installation test completed successfully!"
```

---

## Deployment Checklist

### Before Public Release
- [ ] Test installation on multiple Android versions
- [ ] Verify all architectures work (ARM64, ARMv7, x86)
- [ ] Test with different RAM configurations (1GB, 2GB, 4GB+)
- [ ] Validate Termux API integration across devices
- [ ] Test web interface on various browsers
- [ ] Verify Tailscale integration
- [ ] Check NFT authentication flow
- [ ] Test AI integration with API keys
- [ ] Validate WhatsApp integration
- [ ] Performance test with multiple nodes

### Website Deployment
- [ ] Deploy installation server
- [ ] Configure domain and SSL
- [ ] Set up analytics and monitoring
- [ ] Test CDN distribution
- [ ] Verify GitHub integration
- [ ] Test mobile responsiveness
- [ ] Check QR code generation
- [ ] Validate all download links

### Support Infrastructure
- [ ] Set up Discord community
- [ ] Create documentation site
- [ ] Prepare FAQ and troubleshooting guides
- [ ] Set up support ticket system
- [ ] Create video tutorials
- [ ] Prepare community guidelines

---

## Summary

This complete setup provides:

1. **One-Click Installation** - Users can install chr-node with a single command
2. **Automated Provisioning** - Complete system setup without manual intervention
3. **Web Interface** - Professional interface for wallet connection and node management
4. **Remote Access** - Secure access via Tailscale for node management
5. **Mobile Optimization** - Designed specifically for Android/Termux environment
6. **NFT Authentication** - Secure access based on Chronara Node Pass ownership
7. **AI Integration** - Full AI agent capabilities with tiered access
8. **Service Management** - Easy start/stop/restart with status monitoring
9. **Comprehensive Testing** - Built-in tests for all components
10. **Scalable Architecture** - Ready for thousands of users

Users can now:
- Visit `https://chr-node.network`
- Click "One-Click Install"  
- Paste command in Termux
- Have a fully functional chr-node in 5-10 minutes
- Connect wallet and start earning CHAI tokens immediately

The system is ready for your FUT testing and subsequent public deployment! 🚀