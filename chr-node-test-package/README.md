# chr-node Test Package

This package contains everything needed to test chr-node installation while the repository is private.

## 🧪 Testing Methods

### Method 1: Direct Script Testing

1. Copy the script to your Android device:
   ```bash
   scp termux-one-click-install.sh android-device:/sdcard/
   ```

2. In Termux on Android:
   ```bash
   cp /sdcard/termux-one-click-install.sh .
   chmod +x termux-one-click-install.sh
   ./termux-one-click-install.sh
   ```

### Method 2: Local Web Server

1. Start the local server (requires Python 3):
   ```bash
   python3 simple-server.py
   ```

2. Find your local IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

3. In Termux on Android (connected to same WiFi):
   ```bash
   curl -L http://YOUR_IP:8080/install | bash
   ```

### Method 3: Web Interface Testing

If you want to test the full web interface:

1. Go back to main chr-node directory
2. Start the web server:
   ```bash
   cd web-deployment
   npm install
   npm start
   ```
3. Open http://localhost:3333 in browser
4. Test QR code and copy command functionality

## 📋 Files Included

- `termux-one-click-install.sh` - The main installation script
- `simple-server.py` - Local web server for testing
- `README.md` - This instruction file

## 🎯 What to Test

1. **Script Execution**: Does the installation script run without errors?
2. **Dependency Installation**: Are all packages installed correctly?
3. **Service Creation**: Does chr-node-service command work?
4. **Web Interface**: Can you access http://localhost:3000?
5. **Termux APIs**: Do the API tests pass?
6. **Configuration**: Are all config files generated properly?

## 🐛 Troubleshooting

- **Permission Denied**: Make sure script is executable (`chmod +x`)
- **Network Issues**: Ensure Android and computer are on same WiFi
- **Port Conflicts**: Change PORT in simple-server.py if 8080 is in use
- **Installation Fails**: Check Termux has sufficient storage space

## ✅ Success Criteria

After installation, you should have:
- ✅ chr-node service running
- ✅ Web interface accessible at http://localhost:3000
- ✅ Service management commands available
- ✅ Termux API integration working
- ✅ Configuration files generated

## 🚀 Next Steps

Once testing is complete and everything works:
1. Make repository public
2. Create official release
3. Update documentation
4. Deploy to production

Happy testing! 🧪
