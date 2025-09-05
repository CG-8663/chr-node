# Chr-Node Configuration Guide

Advanced configuration options for optimizing your Chronara Network Lite Node performance and rewards.

## 📖 Configuration Overview

Chr-node uses a hierarchical configuration system with multiple sources:

1. **Environment Variables** (highest priority)
2. **Configuration Files** (`config/chronara.exs`)
3. **Snap Settings** (for snap installations)
4. **Default Values** (lowest priority)

## 🔧 Core Configuration

### Network Ports Configuration

```elixir
# config/chronara.exs
config :chronara_node,
  # Device connection ports (EdgeV2 Protocol)
  edge2_ports: [41046, 41047, 41048],
  
  # P2P network port (Kademlia DHT)
  peer2_port: 51055,
  
  # JSON-RPC interfaces
  rpc_port: 8545,    # HTTP
  rpcs_port: 8443,   # HTTPS
  
  # WebSocket interface
  ws_port: 8546
```

#### Port Configuration via Environment Variables

```bash
# Single EdgeV2 port
export EDGE2_PORT="41046"

# Multiple EdgeV2 ports (comma-separated)
export EDGE2_PORTS="41046,41047,41048"

# P2P network port
export PEER2_PORT="51055"

# RPC ports
export RPC_PORT="8545"
export RPCS_PORT="8443"
```

#### Snap Port Configuration

```bash
# Configure ports via snap
sudo snap set chr-node edge2-ports="41046,41047"
sudo snap set chr-node peer2-port=51055
sudo snap set chr-node rpc-port=8545
sudo snap set chr-node rpcs-port=8443

# Restart to apply changes
sudo snap restart chr-node.service
```

### Data Storage Configuration

```elixir
# config/chronara.exs
config :chronara_node,
  # Primary data directory
  data_dir: System.get_env("DATA_DIR", "./data"),
  
  # Database configuration
  database: [
    # SQLite database for local data
    local_db: "chr_node.sqlite3",
    
    # Network statistics database
    stats_db: "network_stats.sq3",
    
    # Cache size (entries)
    cache_size: 10_000,
    
    # Cache TTL (milliseconds)
    cache_ttl: 300_000  # 5 minutes
  ]
```

#### Data Directory Setup

```bash
# Create custom data directory
sudo mkdir -p /opt/chr-node
sudo chown $USER:$USER /opt/chr-node

# Set via environment
export DATA_DIR="/opt/chr-node"

# Set via snap
sudo snap set chr-node data-dir="/opt/chr-node"
```

## 🌐 Network Configuration

### Chronara Fleet Integration

```elixir
# config/chronara.exs
config :chronara_node,
  # Chronara fleet servers
  fleet_servers: [
    "as1.fleet.chronara.net:41046",  # Tokyo, Japan
    "as2.fleet.chronara.net:41046",  # Singapore
    "us1.fleet.chronara.net:41046",  # New York, USA
    "us2.fleet.chronara.net:41046",  # Los Angeles, USA
    "eu1.fleet.chronara.net:41046",  # London, UK
    "eu2.fleet.chronara.net:41046"   # Frankfurt, Germany
  ],
  
  # Bootstrap peers for P2P discovery
  seed_peers: [
    "bootstrap1.chronara.net:51055",
    "bootstrap2.chronara.net:51055"
  ],
  
  # Network identification
  network_name: "chronara-community",
  chain_id: "chronara-mainnet"
```

### TLS/SSL Configuration

```elixir
# config/chronara.exs
config :chronara_node,
  # TLS configuration for secure connections
  tls_config: [
    # Certificate files (auto-generated if not specified)
    cert_file: System.get_env("TLS_CERT_FILE"),
    key_file: System.get_env("TLS_KEY_FILE"),
    
    # TLS versions
    versions: [:tlsv1.2, :'tlsv1.3'],
    
    # Cipher suites (secp256k1 compatible)
    ciphers: [
      'TLS_AES_256_GCM_SHA384',
      'TLS_AES_128_GCM_SHA256',
      'TLS_CHACHA20_POLY1305_SHA256'
    ]
  ]
```

### Connection Management

```elixir
# config/chronara.exs
config :chronara_node,
  connection_config: [
    # Maximum concurrent connections
    max_connections: 1000,
    
    # Connection timeout (milliseconds)
    connection_timeout: 30_000,
    
    # Keep-alive interval
    keep_alive_interval: 60_000,
    
    # Idle connection timeout
    idle_timeout: 300_000,  # 5 minutes
    
    # Rate limiting
    rate_limit: [
      # Requests per minute per IP
      rpm_per_ip: 100,
      
      # Global requests per minute
      global_rpm: 10_000
    ]
  ]
```

## 🏆 Reward System Configuration

### CHR Token Rewards

```elixir
# config/chronara.exs
config :chronara_node,
  rewards_config: [
    # Reward wallet address (where CHR tokens are sent)
    reward_address: System.get_env("REWARD_ADDRESS"),
    
    # Reward tracking
    track_uptime: true,
    track_bandwidth: true,
    track_connections: true,
    
    # Performance thresholds for bonus rewards
    performance_targets: [
      uptime_threshold: 0.999,     # 99.9% uptime
      latency_threshold: 50,       # 50ms average
      bandwidth_threshold: 1_000_000  # 1MB/s minimum
    ],
    
    # Reward calculation intervals
    reward_interval: 3600_000,    # Hourly (1 hour in ms)
    payout_threshold: 10.0        # Minimum CHR tokens before payout
  ]
```

#### Setting Reward Address

```bash
# Via environment variable
export REWARD_ADDRESS="0x1234567890abcdef1234567890abcdef12345678"

# Via snap configuration
sudo snap set chr-node reward-address="0x1234567890abcdef1234567890abcdef12345678"

# Via configuration file
echo 'export REWARD_ADDRESS="0x1234..."' >> ~/.bashrc
```

### Community Participation Settings

```elixir
# config/chronara.exs
config :chronara_node,
  community_config: [
    # Node operator information
    operator_name: System.get_env("OPERATOR_NAME", "anonymous"),
    operator_email: System.get_env("OPERATOR_EMAIL"),
    
    # Geographic information for regional optimization
    region: System.get_env("NODE_REGION", "unknown"),
    country_code: System.get_env("COUNTRY_CODE", "XX"),
    
    # Community features
    allow_public_stats: true,
    participate_in_governance: true,
    share_performance_data: true
  ]
```

## ⚡ Performance Tuning

### Memory Configuration

```elixir
# config/chronara.exs
config :chronara_node,
  memory_config: [
    # EVM memory settings
    beam_memory_limit: 4_000_000_000,  # 4GB
    
    # Process heap sizes
    min_heap_size: 4096,
    max_heap_size: 1_048_576,
    
    # Garbage collection
    fullsweep_after: 10,
    minor_gcs: 10
  ]
```

### Caching Configuration

```elixir
# config/chronara.exs
config :chronara_node,
  cache_config: [
    # Multi-tier caching
    l1_cache_size: 1_000,      # In-memory cache
    l2_cache_size: 10_000,     # Disk cache
    
    # Cache TTL by type
    peer_cache_ttl: 300_000,        # 5 minutes
    blockchain_cache_ttl: 60_000,   # 1 minute
    stats_cache_ttl: 30_000,        # 30 seconds
    
    # Cache cleanup intervals
    cleanup_interval: 600_000,      # 10 minutes
    
    # Cache persistence
    persist_cache: true,
    cache_file: "chr_node_cache.dat"
  ]
```

### Connection Pool Tuning

```elixir
# config/chronara.exs
config :chronara_node,
  pool_config: [
    # Connection pool sizes
    peer_pool_size: 50,
    rpc_pool_size: 20,
    database_pool_size: 10,
    
    # Pool timeouts
    checkout_timeout: 15_000,
    idle_timeout: 600_000,
    
    # Connection lifecycle
    max_lifetime: 3_600_000,  # 1 hour
    health_check_interval: 60_000  # 1 minute
  ]
```

## 🔐 Security Configuration

### Authentication Settings

```elixir
# config/chronara.exs
config :chronara_node,
  security_config: [
    # Ticket validation
    validate_tickets: true,
    ticket_cache_size: 5_000,
    ticket_ttl: 3600_000,  # 1 hour
    
    # Access control
    allowlist_enabled: false,
    allowlist_file: "allowed_peers.txt",
    
    # Rate limiting
    rate_limiting: [
      enabled: true,
      window_size: 60_000,  # 1 minute
      max_requests: 100,
      ban_duration: 300_000  # 5 minutes
    ],
    
    # DDoS protection
    ddos_protection: [
      enabled: true,
      threshold: 1000,  # requests per minute
      mitigation_time: 600_000  # 10 minutes
    ]
  ]
```

### Cryptographic Settings

```elixir
# config/chronara.exs
config :chronara_node,
  crypto_config: [
    # Supported curves
    curves: [:secp256k1, :ed25519],
    
    # Key management
    auto_generate_keys: true,
    key_rotation_interval: 2_592_000_000,  # 30 days in ms
    
    # Signature validation
    strict_signature_validation: true,
    signature_cache_size: 1_000,
    
    # Encryption settings
    encryption_algorithm: :aes_256_gcm,
    key_derivation: :pbkdf2
  ]
```

## 📊 Monitoring Configuration

### Metrics Collection

```elixir
# config/chronara.exs
config :chronara_node,
  metrics_config: [
    # Enable metrics collection
    enable_metrics: true,
    
    # Metrics retention
    retention_period: 7 * 24 * 3600 * 1000,  # 7 days in ms
    
    # Collection intervals
    collect_interval: 10_000,  # 10 seconds
    
    # Metrics to collect
    collect_system_metrics: true,
    collect_network_metrics: true,
    collect_blockchain_metrics: true,
    collect_performance_metrics: true,
    
    # Export endpoints
    prometheus_endpoint: "/metrics",
    json_metrics_endpoint: "/api/v1/metrics"
  ]
```

### Logging Configuration

```elixir
# config/chronara.exs
config :logger,
  backends: [:console, {LoggerFileBackend, :file}],
  level: :info

# Console logging
config :logger, :console,
  format: "$time [$level] $metadata$message\n",
  metadata: [:node_id, :request_id, :peer_id],
  colors: [enabled: true]

# File logging
config :logger, :file,
  path: System.get_env("LOG_FILE", "./logs/chr_node.log"),
  format: "$time [$level] $metadata$message\n",
  metadata: [:node_id, :request_id, :peer_id, :file, :line],
  level: :debug,
  rotate: %{max_bytes: 10_485_760, keep: 5}  # 10MB, keep 5 files
```

### Health Check Configuration

```elixir
# config/chronara.exs
config :chronara_node,
  health_config: [
    # Health check endpoints
    health_check_path: "/health",
    ready_check_path: "/ready",
    
    # Check intervals
    self_check_interval: 30_000,  # 30 seconds
    
    # Health thresholds
    cpu_threshold: 80.0,      # Percentage
    memory_threshold: 85.0,   # Percentage
    disk_threshold: 90.0,     # Percentage
    
    # Network health
    min_peer_count: 3,
    max_response_time: 5000,  # 5 seconds
    
    # Alerting
    enable_alerts: true,
    alert_webhook: System.get_env("ALERT_WEBHOOK_URL")
  ]
```

## 🔄 Dynamic Configuration

### Runtime Configuration Updates

Chr-node supports runtime configuration updates for certain settings:

```bash
# Update log level without restart
curl -X POST http://localhost:8545/config \
  -d '{"logger_level": "debug"}'

# Update connection limits
curl -X POST http://localhost:8545/config \
  -d '{"max_connections": 1500}'

# Update cache settings
curl -X POST http://localhost:8545/config \
  -d '{"cache_size": 15000}'
```

### Configuration Validation

```bash
# Validate configuration before starting
chr-node --validate-config

# Check configuration syntax
elixir -e "Config.Reader.read!('config/chronara.exs')"

# Test network connectivity with configuration
chr-node --test-network
```

## 📋 Configuration Templates

### Development Configuration

```elixir
# config/dev.exs
import Config

config :chronara_node,
  edge2_port: 41046,
  peer2_port: 51055,
  rpc_port: 8545,
  data_dir: "./data_dev",
  
  # Development-friendly settings
  auto_generate_keys: true,
  debug_mode: true,
  log_level: :debug,
  
  # Relaxed limits for testing
  max_connections: 100,
  rate_limit: false,
  
  # Local fleet for testing
  fleet_servers: ["localhost:41046"]

config :logger, level: :debug
```

### Production Configuration

```elixir
# config/prod.exs
import Config

config :chronara_node,
  edge2_ports: [41046, 41047, 41048],
  peer2_port: 51055,
  rpc_port: 8545,
  rpcs_port: 8443,
  data_dir: "/opt/chr-node/data",
  
  # Production hardening
  auto_generate_keys: false,
  debug_mode: false,
  log_level: :info,
  
  # Production limits
  max_connections: 5000,
  rate_limiting: [enabled: true],
  ddos_protection: [enabled: true],
  
  # Full fleet connectivity
  fleet_servers: [
    "as1.fleet.chronara.net:41046",
    "as2.fleet.chronara.net:41046",
    "us1.fleet.chronara.net:41046",
    "us2.fleet.chronara.net:41046",
    "eu1.fleet.chronara.net:41046",
    "eu2.fleet.chronara.net:41046"
  ]

config :logger, level: :info
```

## 🔍 Configuration Verification

### Verification Checklist

After configuring your chr-node, verify the setup:

```bash
# 1. Check configuration syntax
elixir -e "Config.Reader.read!('config/chronara.exs')" && echo "✅ Config syntax valid"

# 2. Test network ports
netstat -tulpn | grep -E ':(8545|8443|41046|51055)' && echo "✅ Ports configured"

# 3. Verify data directory
test -d $DATA_DIR && test -w $DATA_DIR && echo "✅ Data directory accessible"

# 4. Check TLS certificates
test -f $TLS_CERT_FILE && test -f $TLS_KEY_FILE && echo "✅ TLS certificates found"

# 5. Test fleet connectivity
for fleet in as1 as2 us1 us2 eu1 eu2; do
  ping -c 1 ${fleet}.fleet.chronara.net && echo "✅ $fleet reachable"
done

# 6. Validate reward address format
echo $REWARD_ADDRESS | grep -E '^0x[a-fA-F0-9]{40}$' && echo "✅ Reward address valid"
```

## 📞 Configuration Support

Need help with configuration?

- **Documentation**: [Configuration Wiki](https://deepwiki.com/diodechain/diode_node)
- **Community**: [Discord #chr-node-config](https://discord.chronara.net)
- **Issues**: [GitHub Configuration Issues](https://github.com/CG-8663/chr-node/issues?q=is%3Aissue+label%3Aconfiguration)
- **Examples**: [Configuration Examples Repository](https://github.com/CG-8663/chr-node-configs)