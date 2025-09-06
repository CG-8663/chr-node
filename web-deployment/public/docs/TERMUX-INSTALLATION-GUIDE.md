# chr-node Termux Installation & Testing Guide

## Complete Mobile Deployment with NFT Authentication and AI Integration

This guide walks you through the complete installation and testing of chr-node on Android using Termux, including NFT authentication, AI agent integration, and WhatsApp interface.

## Prerequisites

### Android Device Requirements
- Android 7.0+ (API level 24+)
- 2GB+ RAM recommended (1GB minimum)
- 1GB free storage space
- Active internet connection (WiFi or mobile data)

### Required Apps
1. **Termux** (from F-Droid - recommended)
   - Download: https://f-droid.org/packages/com.termux/
   - Alternative: Google Play Store version
2. **Termux:API** (for hardware integration)
   - Download: https://f-droid.org/packages/com.termux.api/

### API Keys (Optional for AI Features)
- **Gemini API Key**: https://aistudio.google.com/app/apikey
- **Claude API Key**: https://console.anthropic.com/
- **WhatsApp Business API**: https://business.whatsapp.com/

## Installation Process

### Step 1: Download Installation Script

```bash
# In Termux, download the installation script
curl -L -o termux_install.sh https://raw.githubusercontent.com/CG-8663/chr-node/main/scripts/termux_install.sh
chmod +x termux_install.sh
```

### Step 2: Run Installation

```bash
# Execute the installation script
./termux_install.sh
```

The installation script will:
- ✅ Update package repositories
- ✅ Install Elixir, Node.js, Python, and dependencies
- ✅ Download chr-node binary for your architecture
- ✅ Create directory structure and configuration
- ✅ Set up Termux API integration
- ✅ Generate service management scripts
- ✅ Create desktop shortcuts

### Step 3: Development Environment Setup

```bash
# Run the development setup script (created during installation)
$HOME/.chr-node/setup-development.sh
```

This will:
- ✅ Initialize web interface
- ✅ Start chr-node service
- ✅ Launch web server on port 3000
- ✅ Configure NFT authentication system

## Testing and Verification

### Comprehensive Testing Suite

Run the complete mobile testing framework:

```bash
# Execute comprehensive testing (if available on Mac/PC)
./scripts/execute_comprehensive_mobile_testing.sh

# Or test individual components on Android
cd $HOME/.chr-node
```

### Manual Testing Checklist

#### 1. Basic System Tests
```bash
# Test chr-node binary
$HOME/.chr-node/bin/chr-node --version

# Test Termux API availability
$HOME/.chr-node/bin/test-termux-api

# Check service status
chr-node-service status
```

#### 2. Web Interface Tests
1. **Open browser**: Navigate to `http://localhost:3000`
2. **Mobile access**: Use device IP `http://[device-ip]:3000`
3. **QR Code**: Verify QR code generation for wallet linking
4. **Manual Entry**: Test wallet address input validation

#### 3. NFT Authentication Tests
```bash
# Test with mock wallet addresses
# Premium NFT holder (token #42):
0x1234567890123456789012345678901234567890

# Standard NFT holder (token #500): 
0x0987654321098765432109876543210987654321

# Basic NFT holder (token #1500):
0x1111222233334444555566667777888899990000
```

#### 4. AI Agent Tests (requires API keys)
```bash
# Set API keys in environment
export GEMINI_API_KEY="your_gemini_key"
export ANTHROPIC_API_KEY="your_claude_key"

# Restart web interface
pkill -f "npm start"
cd $HOME/.chr-node/web && npm start &
```

Test AI features:
- Basic agent conversation
- Trading insights (Standard/Premium users)
- NFT recommendations (Premium users)
- chr-node optimization advice

## Feature Matrix by Access Level

### Basic Level (Token #1001+)
- ✅ Node status monitoring
- ✅ Basic earnings tracking
- ✅ Simple AI assistant
- ✅ Web interface access
- ❌ Trading features
- ❌ NFT analysis
- ❌ WhatsApp interface

### Standard Level (Token #101-1000)
- ✅ All Basic features
- ✅ Portfolio tracking
- ✅ Trading insights
- ✅ Market analysis
- ✅ Termux API integration
- ✅ WhatsApp notifications
- ❌ Advanced AI features
- ❌ NFT recommendations

### Premium Level (Token #1-100 or Premium NFT)
- ✅ All Standard features
- ✅ Claude AI integration
- ✅ Advanced trading signals
- ✅ NFT market intelligence
- ✅ Full WhatsApp interface
- ✅ ProAgent integration
- ✅ xNomad.fun features
- ✅ Voice messages & file sharing

## Configuration Files

### Main Configuration
```bash
# Location: $HOME/.chr-node/config/chr-node.conf
[node]
id = "your-node-id"
name = "chr-node-android"
data_dir = "/data/data/com.termux/files/home/.chr-node/data"

[network]
listen_port = 8080
api_port = 3000
max_peers = 25

[security]
api_key = "your-api-key"
nft_verification = true
```

### API Keys Configuration
```bash
# Location: $HOME/.chr-node/config/api-keys.env
export GEMINI_API_KEY="your_gemini_key"
export ANTHROPIC_API_KEY="your_claude_key" 
export WHATSAPP_ACCESS_TOKEN="your_whatsapp_token"
export PROAGENT_API_KEY="your_proagent_key"
export XNOMAD_API_KEY="your_xnomad_key"

# Load keys:
source $HOME/.chr-node/config/api-keys.env
```

## Service Management

### Using Service Script
```bash
# Start chr-node
chr-node-service start

# Stop chr-node
chr-node-service stop

# Restart chr-node
chr-node-service restart

# Check status
chr-node-service status
```

### Using Termux Shortcuts (with Termux:Widget)
- **chr-node-start**: Quick start from home screen
- **chr-node-stop**: Quick stop from home screen  
- **chr-node-status**: Check status with notification

### Manual Service Management
```bash
# Start web interface manually
cd $HOME/.chr-node/web
npm start &

# Start chr-node manually
$HOME/.chr-node/bin/chr-node --config $HOME/.chr-node/config/chr-node.conf &

# Check processes
ps aux | grep chr-node
```

## Troubleshooting

### Common Issues

#### 1. Installation Fails
```bash
# Update package lists
pkg update && pkg upgrade

# Check available space
df -h

# Reinstall dependencies manually
pkg install erlang elixir nodejs python git curl
```

#### 2. Web Interface Won't Start
```bash
# Check if port 3000 is available
netstat -tlnp | grep 3000

# Try alternative port
cd $HOME/.chr-node/web
PORT=3001 npm start
```

#### 3. Termux API Not Working
```bash
# Verify Termux:API is installed
pm list packages | grep termux.api

# Test individual APIs
termux-battery-status
termux-wifi-connectioninfo
termux-location --help
```

#### 4. NFT Authentication Fails
- Verify wallet address format (0x + 40 hex characters)
- Check internet connection
- Ensure NFT ownership verification system is working
- Try with mock addresses for testing

#### 5. AI Features Not Working
- Verify API keys are set correctly
- Check internet connection
- Confirm API key permissions and quotas
- Test with simple queries first

#### 6. WhatsApp Integration Issues
- Verify WhatsApp Business API setup
- Check webhook configuration
- Confirm phone number format
- Test authentication flow

### Performance Optimization

#### For Low-End Devices
```bash
# Edit configuration for minimal resource usage
nano $HOME/.chr-node/config/chr-node.conf

[termux]
optimization_level = "ultra_minimal"  
max_peers = 3
battery_optimization = true
data_conservation = true
```

#### For Better Performance
```bash
# Increase peer limits
[network]
max_peers = 50

# Enable full features
[termux]
optimization_level = "standard"
```

## Logs and Debugging

### Log Locations
```bash
# chr-node service logs
tail -f $HOME/.chr-node/logs/chr-node.log

# Web interface logs
tail -f $HOME/.chr-node/logs/web.log

# Installation logs
ls -la $HOME/.chr-node/logs/install-*.log
```

### Debug Mode
```bash
# Enable debug logging
export CHR_NODE_DEBUG=true
chr-node-service restart

# Check debug output
tail -f $HOME/.chr-node/logs/debug.log
```

## Advanced Configuration

### Custom AI Personalities
```bash
# Edit agent configuration
nano $HOME/.chr-node/config/agent-config.json

{
  "personality": {
    "tone": "professional",
    "expertise": ["trading", "nft", "chr-node"],
    "response_style": "concise"
  }
}
```

### Network Optimization
```bash
# Edit network settings
nano $HOME/.chr-node/config/network.conf

[optimization]
mobile_data_mode = true
wifi_preferred = true
background_sync_interval = 300  # 5 minutes
```

### Security Settings
```bash
# Configure security options
nano $HOME/.chr-node/config/security.conf

[authentication]
session_timeout = 3600  # 1 hour
max_failed_attempts = 5
require_2fa = false
```

## Backup and Recovery

### Backup Configuration
```bash
# Create backup
tar -czf chr-node-backup-$(date +%Y%m%d).tar.gz \
  $HOME/.chr-node/config \
  $HOME/.chr-node/keys \
  $HOME/.chr-node/agents

# Store backup
cp chr-node-backup-*.tar.gz /sdcard/
```

### Restore Configuration
```bash
# Extract backup
tar -xzf chr-node-backup-20241205.tar.gz -C $HOME/

# Restart services
chr-node-service restart
```

## Updates and Maintenance

### Update chr-node
```bash
# Download latest version
cd $HOME/.chr-node
wget https://github.com/CG-8663/chr-node/releases/latest/download/chr-node-android-arm64

# Replace binary
mv chr-node-android-arm64 bin/chr-node
chmod +x bin/chr-node

# Restart service
chr-node-service restart
```

### Update Dependencies
```bash
# Update system packages
pkg update && pkg upgrade

# Update Node.js packages
cd $HOME/.chr-node/web
npm update
```

## Support and Community

### Getting Help
- 📧 Email: support@chronara.network
- 💬 Discord: https://discord.gg/chronara
- 📖 Documentation: https://docs.chronara.network
- 🐛 Issues: https://github.com/CG-8663/chr-node/issues

### Contributing
- Fork the repository
- Create feature branches
- Submit pull requests
- Join community discussions

## Security Best Practices

1. **Keep API Keys Secure**: Never share API keys or commit them to repositories
2. **Regular Updates**: Keep chr-node and dependencies updated
3. **Network Security**: Use secure networks and VPN when possible
4. **Backup Regularly**: Maintain regular configuration backups
5. **Monitor Access**: Review authentication logs regularly

## Conclusion

You now have a fully functional chr-node installation on Android with:

- ✅ Complete Termux integration with all 21+ APIs
- ✅ NFT-based authentication system
- ✅ AI agent personalization (Gemini/Claude)
- ✅ ProAgent trading automation
- ✅ xNomad.fun NFT intelligence
- ✅ WhatsApp interface for node management
- ✅ Tiered access based on NFT ownership
- ✅ Mobile-optimized for emerging markets

Your chr-node is ready to participate in the Chronara Network and start earning CHAI tokens while contributing to the decentralized P2P infrastructure!

🎉 **Welcome to the future of mobile blockchain participation!**