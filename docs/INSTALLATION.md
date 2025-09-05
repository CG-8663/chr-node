# Chr-Node Installation Guide

Complete installation guide for Chronara Network Lite Nodes (chr-node) supporting the community P2P infrastructure.

## 📋 Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |
| **CPU** | 2 cores @ 2.0GHz | 4+ cores @ 3.0GHz+ |
| **RAM** | 4GB | 8GB+ |
| **Storage** | 20GB | 50GB+ SSD |
| **Network** | Stable broadband | 100Mbps+ dedicated |
| **Erlang/OTP** | 25+ | 26+ |
| **Elixir** | 1.15+ | 1.15.7 |

### Network Requirements

- **Public IP Address**: Recommended for optimal performance
- **Port Access**: Configurable ports for P2P and RPC services
- **Firewall Configuration**: Allow inbound connections on configured ports
- **Stable Connection**: 99.5%+ uptime target for community rewards

## 🚀 Installation Methods

### Method 1: Snap Package (Recommended)

The snap package is the easiest way to install and manage chr-node:

```bash
# Install chr-node from snap store
sudo snap install chr-node

# Verify installation
chr-node.info

# Start the service
sudo snap start chr-node.service

# Check service status
sudo systemctl status snap.chr-node.service.service
```

#### Snap Configuration

```bash
# View all configuration options
sudo snap get chr-node

# Configure data directory
sudo snap set chr-node data-dir=/your/custom/path

# Configure network ports
sudo snap set chr-node rpc-port=8545
sudo snap set chr-node edge2-port=41046
sudo snap set chr-node peer2-port=51055

# Apply configuration changes
sudo snap restart chr-node.service
```

### Method 2: Build from Source

For developers or advanced users who want to build from source:

```bash
# Install Erlang/OTP and Elixir
sudo apt update
sudo apt install -y build-essential git curl
sudo apt install -y erlang elixir

# Clone chr-node repository
git clone https://github.com/CG-8663/chr-node.git
cd chr-node

# Install dependencies
mix local.hex --force
mix local.rebar --force
mix deps.get

# Run tests (optional)
mix test

# Build production release
MIX_ENV=prod mix release chr_node

# Start the node
./_build/prod/rel/chr_node/bin/chr_node start
```

### Method 3: Docker Container

Run chr-node in a Docker container:

```bash
# Pull the chr-node image
docker pull ghcr.io/cg-8663/chr-node:latest

# Run container with data persistence
docker run -d \
  --name chr-node \
  --restart unless-stopped \
  -p 8545:8545 \
  -p 41046:41046 \
  -p 51055:51055 \
  -v chr-node-data:/app/data \
  -e DATA_DIR=/app/data \
  ghcr.io/cg-8663/chr-node:latest

# Check container logs
docker logs -f chr-node

# Check node status
docker exec chr-node /app/bin/chr_node eval "IO.puts('Chr-Node Status: Active')"
```

## ⚙️ Configuration

### Environment Variables

Chr-node uses environment variables for configuration:

```bash
# Core configuration
export DATA_DIR="/path/to/data"           # Data storage directory
export RPC_PORT="8545"                    # JSON-RPC HTTP port
export RPCS_PORT="8443"                   # JSON-RPC HTTPS port
export EDGE2_PORT="41046"                 # Device connection port
export PEER2_PORT="51055"                 # P2P network port

# Network configuration
export SEED_LIST="peer1:port,peer2:port"  # Bootstrap peers
export FLEET_ADDR="fleet.chronara.net"    # Fleet server address

# Advanced configuration
export CHR_NODE_NAME="my-chr-node"        # Custom node identifier
export LOG_LEVEL="info"                   # Logging level
export REWARD_ADDRESS="0x..."             # CHR token reward address
```

### Configuration File

Create a configuration file at `config/chronara.exs`:

```elixir
# config/chronara.exs
import Config

# Network configuration
config :chronara_node,
  # Core network ports
  rpc_port: System.get_env("RPC_PORT", "8545") |> String.to_integer(),
  rpcs_port: System.get_env("RPCS_PORT", "8443") |> String.to_integer(),
  edge2_port: System.get_env("EDGE2_PORT", "41046") |> String.to_integer(),
  peer2_port: System.get_env("PEER2_PORT", "51055") |> String.to_integer(),
  
  # Chronara-specific configuration
  fleet_address: System.get_env("FLEET_ADDR", "fleet.chronara.net"),
  reward_address: System.get_env("REWARD_ADDRESS"),
  node_name: System.get_env("CHR_NODE_NAME", "chr-node-#{:rand.uniform(9999)}"),
  
  # Performance tuning
  max_connections: 1000,
  connection_timeout: 30_000,
  cache_size: 1000

# Logger configuration
config :logger, :console,
  format: "$time [$level] $metadata$message\n",
  metadata: [:node, :request_id]
```

## 🔧 System Optimization

### Linux Kernel Optimization

For optimal network performance, enable TCP BBR congestion control:

```bash
# Enable TCP BBR
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf

# Load BBR module
echo 'tcp_bbr' | sudo tee -a /etc/modules-load.d/modules.conf

# Apply changes
sudo modprobe tcp_bbr
sudo sysctl --system

# Verify BBR is active
sysctl net.ipv4.tcp_congestion_control
```

### Firewall Configuration

Configure UFW firewall for chr-node:

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (if using remote access)
sudo ufw allow ssh

# Allow chr-node ports
sudo ufw allow 8545/tcp comment 'Chr-Node RPC HTTP'
sudo ufw allow 8443/tcp comment 'Chr-Node RPC HTTPS'
sudo ufw allow 41046/tcp comment 'Chr-Node Edge2'
sudo ufw allow 51055/tcp comment 'Chr-Node P2P'

# Check firewall status
sudo ufw status verbose
```

### File Descriptor Limits

Increase file descriptor limits for high-connection nodes:

```bash
# Edit limits configuration
sudo nano /etc/security/limits.conf

# Add these lines:
* soft nofile 65536
* hard nofile 65536

# Edit systemd configuration
sudo nano /etc/systemd/system.conf

# Uncomment and set:
DefaultLimitNOFILE=65536

# Reboot to apply changes
sudo reboot
```

## 🔍 Verification

### Post-Installation Checks

After installation, verify chr-node is working correctly:

```bash
# Check chr-node version
chr-node.info

# Verify network connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"node_info","params":[],"id":1}' \
  http://localhost:8545/

# Check service status
sudo systemctl status snap.chr-node.service.service

# View live logs
journalctl -u snap.chr-node.service.service -f

# Test P2P connectivity
telnet localhost 51055
```

### Health Monitoring

Set up basic monitoring for your chr-node:

```bash
# Create monitoring script
cat > /usr/local/bin/chr-node-monitor << 'EOF'
#!/bin/bash
# Chr-Node Health Monitor

# Check if chr-node process is running
if ! pgrep -x "chr_node" > /dev/null; then
    echo "❌ Chr-Node process not running"
    exit 1
fi

# Check RPC port response
if ! curl -s -f http://localhost:8545/ > /dev/null; then
    echo "❌ Chr-Node RPC not responding"
    exit 1
fi

echo "✅ Chr-Node healthy"
exit 0
EOF

# Make executable
sudo chmod +x /usr/local/bin/chr-node-monitor

# Test monitor
/usr/local/bin/chr-node-monitor
```

## 🎯 Platform-Specific Instructions

### Raspberry Pi (ARM64)

For Raspberry Pi deployment:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y build-essential git curl
sudo apt install -y erlang elixir

# Optimize for ARM architecture
export QEMU_LD_PREFIX=/usr/aarch64-linux-gnu

# Build from source (recommended for Pi)
git clone https://github.com/CG-8663/chr-node.git
cd chr-node
mix deps.get
MIX_ENV=prod mix release chr_node
```

### macOS (Apple Silicon)

For macOS with Apple Silicon:

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Erlang and Elixir
brew install erlang elixir

# Clone and build
git clone https://github.com/CG-8663/chr-node.git
cd chr-node
mix deps.get
MIX_ENV=prod mix release chr_node

# Run
./_build/prod/rel/chr_node/bin/chr_node start
```

### Cloud Deployment

For cloud instance deployment:

```bash
# AWS/GCP/Azure instance setup
sudo apt update && sudo apt install -y snapd

# Enable snap service
sudo systemctl enable --now snapd.socket

# Install chr-node
sudo snap install chr-node

# Configure for cloud environment
sudo snap set chr-node data-dir=/opt/chr-node-data
sudo mkdir -p /opt/chr-node-data
sudo chown snap_daemon:snap_daemon /opt/chr-node-data

# Start service
sudo snap start chr-node.service
```

## 🚨 Troubleshooting

### Common Issues

**1. Installation Fails**
```bash
# Check system requirements
elixir --version
erl -version

# Update package lists
sudo apt update

# Install missing dependencies
sudo apt install -y build-essential
```

**2. Permission Denied**
```bash
# Fix data directory permissions
sudo chown -R $USER:$USER $DATA_DIR

# Fix snap permissions
sudo snap connect chr-node:network-bind
```

**3. Port Already in Use**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :8545

# Kill conflicting process or change port
sudo snap set chr-node rpc-port=8546
```

**4. Node Not Connecting to Network**
```bash
# Check firewall
sudo ufw status

# Test network connectivity
ping fleet.chronara.net

# Check DNS resolution
nslookup fleet.chronara.net
```

### Log Analysis

View and analyze chr-node logs:

```bash
# View recent logs
journalctl -u snap.chr-node.service.service --since "1 hour ago"

# Follow live logs
journalctl -u snap.chr-node.service.service -f

# Filter error logs
journalctl -u snap.chr-node.service.service --since today | grep -i error

# Export logs for analysis
journalctl -u snap.chr-node.service.service --since "24 hours ago" > chr-node.log
```

## 🎉 Next Steps

After successful installation:

1. **[Configure Your Node](CONFIGURATION.md)** - Advanced configuration options
2. **[Monitor Performance](MONITORING.md)** - Set up monitoring and alerts
3. **[Join Community](https://community.chronara.net)** - Connect with other operators
4. **[Track Rewards](https://rewards.chronara.net)** - Monitor your CHR token earnings

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/CG-8663/chr-node/issues)
- **Community**: [Discord](https://discord.chronara.net)
- **Documentation**: [docs.chronara.net](https://docs.chronara.net)
- **Wiki**: [DeepWiki](https://deepwiki.com/diodechain/diode_node)