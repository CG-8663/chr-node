#!/bin/bash
# Temporary authenticated installation script for private repo testing

echo "🔐 Downloading chr-node installation script with authentication..."

# Use gh to download the raw file with authentication
gh api repos/CG-8663/chr-node/contents/scripts/termux-one-click-install.sh \
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
