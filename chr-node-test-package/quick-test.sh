#!/bin/bash

echo "🧪 Quick Test of chr-node Installation"
echo "====================================="

# Test script syntax
if bash -n termux-one-click-install.sh; then
    echo "✅ Installation script syntax is valid"
else
    echo "❌ Installation script has syntax errors"
    exit 1
fi

# Show script size
LINES=$(wc -l < termux-one-click-install.sh)
echo "📊 Script size: $LINES lines"

# Test dependencies
echo ""
echo "🔍 Testing dependencies..."

if command -v python3 &> /dev/null; then
    echo "✅ Python 3 available for local server"
else
    echo "❌ Python 3 not found - install for local server testing"
fi

if command -v curl &> /dev/null; then
    echo "✅ curl available"
else
    echo "❌ curl not found"
fi

echo ""
echo "📋 Ready for testing!"
echo ""
echo "Methods available:"
echo "1. Direct: Copy script to Android and run"
echo "2. Server: python3 simple-server.py"
echo "3. Web UI: Go to ../web-deployment && npm start"
echo ""
echo "See README.md for detailed instructions."
