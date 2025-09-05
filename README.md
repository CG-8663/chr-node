![Chronara Logo](https://chronara.net/images/logo-trans.svg)
> ### **Community. Secure. Decentralized.**

# Chronara Network Lite Node (chr-node)

🚀 **Lightweight P2P infrastructure nodes for the Chronara Network community**

Chr-nodes are the backbone of Chronara's decentralized community infrastructure. Each node helps devices communicate securely and efficiently through the enhanced Chronara network with multi-TLD support and superior quality of service.

**Community Participation**: Run a chr-node to support the Chronara ecosystem and earn rewards while providing essential P2P infrastructure for users worldwide.

## ✨ **Key Features**

### 🌐 **Enhanced Network Protocol**
- **Multi-TLD Support**: Native support for `.com`, `.net`, `.ai`, `.io` domains
- **Chronara Fleet Integration**: Connects to 6 regional fleet nodes for optimal routing
- **Advanced QoS**: <50ms latency targets with dedicated bandwidth allocation
- **Community Rewards**: Earn tokens for providing reliable node infrastructure

### 🔐 **Security & Performance**
- **Dual-Curve Cryptography**: secp256k1 + ed25519 compatibility
- **End-to-End Encryption**: All P2P communications secured
- **DDoS Protection**: Built-in rate limiting and connection management
- **Automated SSL**: Certificate management and renewal

### 🏗️ **Community Infrastructure**
- **Lightweight Deployment**: Minimal resource requirements
- **Snap Package Installation**: Easy one-command setup
- **Regional Distribution**: Support global network expansion
- **Reputation System**: Gain reputation for consistent uptime

## 🚀 **Quick Start**

### Installation

#### Snap Package (Recommended)
```bash
# Install chr-node snap package
sudo snap install chr-node
```

#### Build from Source
```bash
# Clone repository
git clone https://github.com/CG-8663/chr-node.git
cd chr-node

# Install dependencies
mix deps.get

# Build release
mix release chr_node

# Run node
./_build/prod/rel/chr_node/bin/chr_node start
```

### Configuration

After installation, configure your node:

```bash
# View current configuration
sudo snap get chr-node

# Set custom data directory (optional)
sudo snap set chr-node data-dir=/path/to/your/data

# Set custom ports (optional)
sudo snap set chr-node rpc-port=8545
sudo snap set chr-node edge2-port=41046
sudo snap set chr-node peer2-port=41047
```

### Network Optimization

For optimal performance on Linux:

```bash
# Enable TCP BBR congestion control
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf

# Load BBR module
echo 'tcp_bbr' | sudo tee -a /etc/modules-load.d/modules.conf

# Apply settings
sudo modprobe tcp_bbr 
sudo sysctl --system
```

## 📊 **Node Requirements**

### **Minimum System Requirements**
| Component | Requirement |
|-----------|-------------|
| **CPU** | 2 cores, 2.0GHz |
| **Memory** | 4GB RAM |
| **Storage** | 20GB available space |
| **Network** | Stable internet, public IP recommended |
| **OS** | Ubuntu 22.04+ or compatible Linux |

### **Recommended for Production**
| Component | Recommended |
|-----------|-------------|
| **CPU** | 4+ cores, 3.0GHz+ |
| **Memory** | 8GB+ RAM |
| **Storage** | 50GB+ SSD |
| **Network** | Dedicated bandwidth 100Mbps+ |
| **Uptime** | 99.9% availability target |

## 🔧 **Operations**

### **Monitor Node Status**
```bash
# Check service status
sudo systemctl status snap.chr-node.service.service

# View node information
chr-node.info

# Check connectivity
chr-node.env
```

### **View Service Logs**
```bash
# Get last restart timestamp
systemctl show -p ActiveEnterTimestamp snap.chr-node.service.service

# View logs around restart
journalctl -u snap.chr-node.service.service --since "2025-01-01 00:00:00"

# Follow live logs
journalctl -u snap.chr-node.service.service -f
```

### **Node Management**
```bash
# Start node service
sudo systemctl start snap.chr-node.service.service

# Stop node service
sudo systemctl stop snap.chr-node.service.service

# Restart node service
sudo systemctl restart snap.chr-node.service.service

# Enable auto-start on boot
sudo systemctl enable snap.chr-node.service.service
```

## 🎯 **Community Participation**

### **Node Operation Benefits**
- **Network Rewards**: Earn CHR tokens for reliable service
- **Community Recognition**: Build reputation in the Chronara ecosystem
- **Network Growth**: Support global P2P infrastructure expansion
- **Technical Learning**: Gain experience with cutting-edge P2P technology

### **Best Practices**
- **Maintain High Uptime**: Target 99.9% availability
- **Regular Updates**: Keep your node software current
- **Monitor Performance**: Watch bandwidth and response times
- **Community Engagement**: Participate in forums and governance

### **Reward Structure**
- **Base Rewards**: Hourly payouts for online nodes
- **Performance Bonuses**: Extra rewards for low-latency, high-uptime nodes
- **Regional Incentives**: Additional rewards for underserved geographic areas
- **Referral Program**: Earn bonuses for bringing new nodes online

## 🌍 **Network Architecture**

### **Chronara Fleet Integration**
```
Regional Fleet Nodes:
  📍 as1.fleet.chronara.net (Tokyo, Japan)
  📍 as2.fleet.chronara.net (Singapore)
  📍 us1.fleet.chronara.net (New York, USA)
  📍 us2.fleet.chronara.net (Los Angeles, USA)  
  📍 eu1.fleet.chronara.net (London, UK)
  📍 eu2.fleet.chronara.net (Frankfurt, Germany)
```

### **Chr-Node Role**
- **Local Relay**: Handle regional P2P traffic
- **Content Caching**: Store frequently accessed data
- **Load Distribution**: Reduce load on fleet infrastructure
- **Mesh Networking**: Create resilient communication paths

## 🔗 **Technical Specifications**

### **Network Protocols**
- **Edge v2 Protocol**: Enhanced P2P communication
- **WebSocket Support**: Real-time bidirectional communication
- **RPC Interface**: JSON-RPC API for integration
- **Multi-TLD BNS**: Blockchain name service with domain separation

### **Blockchain Integration**
- **Moonbeam Monitoring**: Cross-chain compatibility
- **Smart Contracts**: Fleet registry, BNS, and rewards contracts
- **Wallet Integration**: Secure key management and transactions
- **Token Economics**: CHR token rewards and staking

### **Development Stack**
- **Elixir/OTP**: High-concurrency, fault-tolerant runtime
- **Phoenix Framework**: Web application framework
- **ExQLite**: Embedded database for local data
- **Certmagex**: Automated certificate management

## 📖 **Documentation**

### **Getting Started Guides**
- **[Installation Guide](docs/installation.md)** - Complete setup instructions
- **[Configuration Guide](docs/configuration.md)** - Advanced configuration options
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Performance Tuning](docs/performance.md)** - Optimization best practices

### **Advanced Topics**
- **[Network Protocol](docs/protocol.md)** - Technical protocol specification
- **[API Reference](docs/api.md)** - Complete RPC API documentation
- **[Community Governance](docs/governance.md)** - Participate in network decisions
- **[Reward System](docs/rewards.md)** - Understand the incentive structure

## 🛠️ **Development**

### **Build Requirements**
- Elixir 1.15+ with OTP 25+
- Erlang 25+
- Git for version control
- GCC compiler for native dependencies

### **Development Setup**
```bash
# Clone repository
git clone https://github.com/CG-8663/chr-node.git
cd chr-node

# Install dependencies  
mix deps.get

# Run tests
mix test

# Start development server
mix run --no-halt

# Format code
mix format

# Run linter
mix lint
```

### **Contributing**
We welcome contributions from the community! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Code style guidelines
- Testing requirements
- Pull request process
- Community standards

## 📊 **Performance Metrics**

### **Typical Node Performance**
| Metric | Community Node | Fleet Node |
|--------|----------------|------------|
| **Latency** | 50-100ms | <30ms |
| **Throughput** | 100-500 Mbps | 1+ Gbps |
| **Connections** | 100-1000 | 10k+ |
| **Uptime Target** | 99.5% | 99.9% |

### **Resource Usage**
| Resource | Light Load | Heavy Load |
|----------|------------|------------|
| **CPU** | 5-15% | 30-60% |
| **Memory** | 100-500MB | 1-2GB |
| **Network** | 1-10MB/s | 50-100MB/s |
| **Storage** | 1-5GB | 10-20GB |

## 🔐 **Security**

### **Security Features**
- **Encrypted Communication**: All traffic encrypted end-to-end
- **Authenticated Connections**: Cryptographic node identity verification  
- **Rate Limiting**: Built-in DDoS protection
- **Secure Storage**: Encrypted local data and wallet files

### **Security Best Practices**
- Keep your node software updated
- Use strong wallet passwords
- Monitor for unusual network activity
- Regular security audits and updates
- Firewall configuration for exposed ports

## 📞 **Support**

### **Community Support**
- **GitHub Issues**: [Report bugs and request features](https://github.com/CG-8663/chr-node/issues)
- **Discord**: Join the Chronara community Discord server
- **Forums**: [Community forums](https://community.chronara.net)
- **Documentation**: [Complete guides and tutorials](https://docs.chronara.net)

### **Professional Support**
- **Enterprise Nodes**: Dedicated support for large deployments
- **Custom Integration**: API integration assistance
- **Performance Consulting**: Optimization and scaling guidance
- **Training**: Node operator certification programs

## 📄 **License**

This project is licensed under the **Diode License, Version 1.1** - see the [LICENSE](LICENSE) file for details.

Based on [Diode Network Node](https://github.com/diodechain/diode_node) with Chronara-specific enhancements for community participation and multi-TLD support.

## 🎯 **Roadmap**

### **Current (v1.0.0)**
- ✅ Multi-TLD support integration
- ✅ Chronara fleet connectivity
- ✅ Community reward system
- ✅ Snap package distribution

### **Upcoming (v1.1.0)**
- 🔄 Enhanced monitoring dashboard
- 🔄 Automated node health checks
- 🔄 Mobile management app
- 🔄 Advanced analytics

### **Future (v2.0.0)**
- 🔮 AI-powered traffic optimization
- 🔮 Cross-chain bridge integration
- 🔮 Advanced governance features
- 🔮 Enterprise clustering support

---

**🚀 Join the Chronara Community - Power the Future of P2P Networking**

Transform internet infrastructure with decentralized, community-driven nodes that provide superior performance, security, and rewards.

[Get Started](https://github.com/CG-8663/chr-node/releases/latest) • [Documentation](https://docs.chronara.net) • [Community](https://community.chronara.net)