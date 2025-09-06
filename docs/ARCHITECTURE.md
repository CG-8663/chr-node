# Chr-Node Architecture

Comprehensive architecture documentation for Chronara Network Lite Nodes, based on the proven Diode Node architecture with community-focused enhancements.

## 🏗️ System Overview

Chr-node is built on Elixir/OTP using the Actor Model and supervisor patterns, providing fault-tolerant, concurrent processing for P2P networking operations. The architecture consists of several interconnected layers that work together to provide reliable community infrastructure.

```
┌─────────────────────────────────────────────────────────────┐
│                    Chr-Node Architecture                     │
├─────────────────────────────────────────────────────────────┤
│  Application Layer                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  Community      │  │   Reward        │  │   Fleet     │  │
│  │  Management     │  │   System        │  │ Integration │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Network Services Layer                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   EdgeV2        │  │   P2P Network   │  │   JSON-RPC  │  │
│  │   Protocol      │  │   (Kademlia)    │  │   Server    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Data Persistence Layer                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   SQLite DB     │  │  Multi-tier     │  │ State Store │  │
│  │   Storage       │  │    Cache        │  │   (ETS)     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Blockchain Integration Layer                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   Ticket        │  │   Multi-TLD     │  │   Smart     │  │
│  │  Validation     │  │     BNS         │  │ Contracts   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Core Infrastructure Layer                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   Supervisor    │  │   Process       │  │   Security  │  │
│  │     Tree        │  │   Manager       │  │   Layer     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🧩 Core Components

### 1. ChronaraNode Application Module

The main application supervisor that coordinates all system components:

```elixir
defmodule ChronaraNode do
  use Application
  
  def start(_type, _args) do
    children = [
      # Core infrastructure
      Globals,
      Stats,
      {Exqlite.LRU, [name: Network.Stats.LRU]},
      
      # Data persistence
      Network.Stats,
      supervisor(Model.Sql),
      TicketStore,
      
      # Scheduling and maintenance
      Cron,
      
      # Network services
      supervisor(Channels),
      {PubSub, []},
      MerkleTree,
      
      # Connection management
      supervisor(ClientBinaryStore),
      supervisor(Connection.Cache),
      supervisor(Connection.Pool),
      
      # Blockchain integration
      supervisor(RemoteChain.Supervisor),
      RemoteRpc,
      
      # P2P networking
      Connectivity,
      Object.Manager,
      Object.Server,
      
      # Network protocol servers
      Network.Server.child_specs(),
      Network.PeerHandler.child_spec(),
      Network.RpcHttp.child_spec(),
      Network.RpcHttps.child_spec()
    ]
    
    Supervisor.start_link(children, 
      strategy: :rest_for_one, 
      name: ChronaraNode.Supervisor
    )
  end
end
```

### 2. Network Services Architecture

#### EdgeV2 Protocol Server
Handles secure device-to-device connections with TLS 1.2 and ticket-based authentication:

```elixir
# Network.EdgeV2 handles device connections
┌─────────────────┐    TLS 1.2 + Tickets    ┌─────────────────┐
│   IoT Device    │ ◄─────────────────────► │   Chr-Node      │
│                 │                         │   EdgeV2        │
└─────────────────┘                         └─────────────────┘
```

**Key Features:**
- **TLS 1.2 Authentication**: Using secp256k1 certificates
- **Ticket Validation**: Cryptographic proof of payment/access
- **Port Forwarding**: Secure tunneling between devices
- **Connection Tracking**: State management and duplicate prevention

#### P2P Network Layer
Implements Kademlia DHT for peer discovery and message routing:

```elixir
# P2P Network Topology
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Chr-Node   │ ◄──► │  Chr-Node   │ ◄──► │  Chr-Node   │
│     A       │     │     B       │     │     C       │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                   ┌─────────────┐
                   │ Fleet Node  │
                   │ (Chronara)  │
                   └─────────────┘
```

**Key Features:**
- **Distributed Hash Table**: Node discovery and data storage
- **Peer Routing**: Efficient message forwarding
- **Network Resilience**: Automatic peer replacement and healing
- **Fleet Integration**: Connection to Chronara's regional infrastructure

#### JSON-RPC Server
Provides HTTP/HTTPS API access for external integration:

```elixir
# RPC Interface Structure
POST /rpc HTTP/1.1
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "method": "chr_node_info",
  "params": [],
  "id": 1
}
```

**Available Methods:**
- `chr_node_info`: Node status and information
- `peer_list`: Connected peer information
- `network_stats`: Performance metrics
- `reward_status`: CHAI token earning information
- `fleet_status`: Connection status to Chronara fleet

### 3. Data Persistence Layer

#### SQLite Database Storage
Local persistent storage for node data and statistics:

```sql
-- Core data tables
CREATE TABLE node_stats (
    timestamp INTEGER PRIMARY KEY,
    connections INTEGER,
    bandwidth_in INTEGER,
    bandwidth_out INTEGER,
    uptime_seconds INTEGER
);

CREATE TABLE peer_history (
    peer_id TEXT PRIMARY KEY,
    first_seen INTEGER,
    last_seen INTEGER,
    connection_count INTEGER,
    reliability_score REAL
);

CREATE TABLE reward_tracking (
    period_start INTEGER PRIMARY KEY,
    period_end INTEGER,
    uptime_score REAL,
    performance_score REAL,
    chr_tokens_earned REAL
);
```

#### Multi-Tier Caching System
Intelligent caching for performance optimization:

```elixir
# Cache Hierarchy
┌─────────────┐
│   L1 Cache  │  ◄── In-memory ETS tables (fastest)
│   (Memory)  │
└─────────────┘
       │
┌─────────────┐
│   L2 Cache  │  ◄── Local SQLite cache (medium)
│  (SQLite)   │
└─────────────┘
       │
┌─────────────┐
│ Blockchain  │  ◄── Remote RPC calls (slowest)
│   Source    │
└─────────────┘
```

**Cache Strategies:**
- **Peer Information**: 5-minute TTL
- **Blockchain Data**: 1-minute TTL for blocks, 5-minute for contracts
- **Network Statistics**: 30-second TTL
- **Ticket Validation**: 1-hour TTL with background refresh

### 4. Blockchain Integration

#### Multi-TLD BNS Resolution
Enhanced Blockchain Name Service supporting multiple top-level domains:

```elixir
# BNS Resolution Flow
"mysite.chronara.com" 
    ↓
Parse TLD → "com"
    ↓
Create namespace → "com:mysite"
    ↓
Blockchain lookup → Contract address
    ↓
Return device address
```

**Supported TLDs:**
- `.com`: Commercial domains
- `.net`: Network infrastructure
- `.ai`: AI and tech services  
- `.io`: Developer and API services
- `.org`: Community organizations
- `.app`: Applications and services

#### Ticket Validation System
Cryptographic proof system for access control and monetization:

```elixir
# Ticket Structure
%Ticket{
  epoch: current_epoch(),
  bytes_limit: 1_000_000,
  signature: cryptographic_signature,
  fleet_allowlist: ["fleet.chronara.net"],
  payment_proof: chr_token_transaction_hash
}
```

**Validation Steps:**
1. **Epoch Verification**: Check ticket is current
2. **Signature Validation**: Verify cryptographic signature
3. **Fleet Authorization**: Confirm fleet node permission
4. **Usage Tracking**: Monitor bandwidth consumption
5. **Payment Verification**: Validate CHAI token payment

### 5. Security Architecture

#### TLS Configuration
Modern TLS setup with cryptographic best practices:

```elixir
# TLS Configuration
tls_config = [
  versions: [:'tlsv1.2', :'tlsv1.3'],
  ciphers: [
    'TLS_AES_256_GCM_SHA384',
    'TLS_AES_128_GCM_SHA256', 
    'TLS_CHACHA20_POLY1305_SHA256'
  ],
  cert_file: "chr_node.crt",
  key_file: "chr_node.key",
  verify: :verify_peer,
  fail_if_no_peer_cert: true
]
```

#### Authentication & Authorization
Multi-layered security approach:

```elixir
# Security Layers
1. TLS Certificate Authentication (Node Identity)
2. Ticket-based Authorization (Access Rights)  
3. Rate Limiting (DoS Protection)
4. Connection State Tracking (Duplicate Prevention)
5. Fleet Allowlist (Trusted Node Network)
```

## 🔄 Process Supervision Tree

Chr-node uses OTP supervision patterns for fault tolerance:

```
ChronaraNode.Supervisor (rest_for_one)
├── Globals (permanent)
├── Stats (permanent) 
├── Network.Stats.LRU (permanent)
├── Network.Stats (permanent)
├── Model.Sql.Supervisor (permanent)
│   ├── Model.Sql.Worker
│   └── Model.Sql.Cache
├── TicketStore (permanent)
├── Cron (permanent)
├── Channels.Supervisor (permanent)
├── PubSub (permanent)
├── MerkleTree (permanent)
├── Connection.Cache.Supervisor (permanent)
├── Connection.Pool.Supervisor (permanent)
├── RemoteChain.Supervisor (permanent)
│   ├── RemoteChain.RPC
│   ├── RemoteChain.Monitor
│   └── RemoteChain.Cache
├── RemoteRpc (permanent)
├── Connectivity (permanent)
├── Object.Manager (permanent)
├── Object.Server (permanent)
├── Network.EdgeV2.Listener (transient)
├── Network.PeerHandler (transient)  
├── Network.RpcHttp (transient)
└── Network.RpcHttps (transient)
```

**Supervision Strategies:**
- **rest_for_one**: If a process crashes, restart it and all processes started after it
- **permanent**: Always restart crashed processes
- **transient**: Only restart if process terminates abnormally
- **temporary**: Never restart (for network listeners)

## 🌐 Network Protocols

### EdgeV2 Protocol Specification

**Connection Establishment:**
```
Client                          Chr-Node
  │                               │
  ├─── TLS Handshake ─────────────┤
  │                               │
  ├─── Ticket Presentation ──────┤
  │                               │
  ├─── Authentication Success ────┤
  │                               │
  ├─── Port Forward Request ──────┤
  │                               │
  ├─── Connection Established ────┤
  │                               │
```

**Message Format:**
```elixir
# Binary message structure
<<
  version::8,           # Protocol version (2)
  message_type::8,      # Message type identifier
  flags::16,           # Protocol flags
  length::32,          # Message length
  payload::binary      # Message payload
>>
```

### P2P Network Protocol

**Kademlia DHT Operations:**
```elixir
# DHT Message Types
1. PING       - Node liveness check
2. STORE      - Store value at node
3. FIND_NODE  - Locate closest nodes to ID
4. FIND_VALUE - Retrieve value by key

# Message Structure
%P2PMessage{
  type: :ping | :store | :find_node | :find_value,
  node_id: <<160::binary>>,  # 160-bit node identifier
  payload: term(),
  signature: <<64::binary>>  # Cryptographic signature
}
```

## 📊 Performance Characteristics

### Scalability Metrics

| Metric | Community Node | Fleet Node |
|--------|----------------|------------|
| **Max Connections** | 1,000 | 10,000+ |
| **Throughput** | 100 Mbps | 1+ Gbps |
| **Latency** | 50-100ms | <30ms |
| **Memory Usage** | 100-500MB | 1-4GB |
| **CPU Usage** | 5-25% | 10-50% |
| **Storage I/O** | 10-50 MB/s | 100+ MB/s |

### Optimization Strategies

#### Connection Management
```elixir
# Connection pooling and management
defmodule Connection.Pool do
  @max_connections 1000
  @connection_timeout 30_000
  @idle_timeout 300_000
  
  # Pool strategies
  - Round-robin connection distribution
  - Health-check based failover
  - Automatic connection recycling
  - Load-based scaling
end
```

#### Memory Optimization
```elixir
# Memory management strategies
1. Process-based isolation
2. Garbage collection tuning
3. ETS table optimization  
4. Binary data streaming
5. Reference counting for shared data
```

#### Network Optimization  
```elixir
# Network performance tuning
1. TCP/IP stack optimization
2. Buffer size tuning
3. Compression for large payloads
4. Connection keep-alive
5. Pipeline request processing
```

## 🔧 Configuration Architecture

### Environment-Based Configuration
Configuration priority (highest to lowest):

1. **Environment Variables** - Runtime configuration
2. **Config Files** - `config/chronara.exs`
3. **Default Values** - Built-in defaults

```elixir
# Configuration structure
config :chronara_node,
  # Network configuration
  network: [
    edge2_ports: [41046, 41047],
    peer2_port: 51055,
    rpc_port: 8545,
    rpcs_port: 8443
  ],
  
  # Storage configuration  
  storage: [
    data_dir: "./data",
    cache_size: 10_000,
    db_pool_size: 5
  ],
  
  # Performance tuning
  performance: [
    max_connections: 1000,
    connection_timeout: 30_000,
    worker_pool_size: 10
  ],
  
  # Security settings
  security: [
    tls_versions: [:'tlsv1.2', :'tlsv1.3'],
    require_tickets: true,
    rate_limiting: true
  ]
```

## 📈 Monitoring & Observability

### Metrics Collection
Real-time metrics for operational visibility:

```elixir
# Collected Metrics
- Connection count and status
- Bandwidth utilization (in/out)
- Request latency percentiles
- Error rates by category
- Memory and CPU utilization
- Cache hit ratios
- P2P network health
- Blockchain sync status
- Reward earning rate
```

### Health Monitoring
Multi-layered health checking:

```elixir
# Health Check Layers
1. Process Health    - All supervised processes running
2. Network Health    - P2P connections active
3. Storage Health    - Database accessible
4. Performance      - Latency within thresholds
5. Integration      - Fleet connectivity status
```

## 🚀 Deployment Architecture

### Container Deployment
```dockerfile
# Multi-stage build process
FROM erlang:26-alpine AS builder
# ... build chr-node release

FROM alpine:3.18 AS runtime
# ... create runtime environment
COPY --from=builder /app/_build/prod/rel/chr_node /app/
EXPOSE 8545 8443 41046 51055
CMD ["/app/bin/chr_node", "start"]
```

### Snap Package Structure
```yaml
# Snap application definition
apps:
  service:
    command: bin/chr_node start
    daemon: simple
    plugs: [network, network-bind, home]
    
  info:
    command: bin/chr_node rpc ChronaraNode.Cmd.status
    plugs: [network]
```

## 🔮 Future Architecture Enhancements

### Planned Improvements

1. **WebAssembly Integration**: Browser-based chr-node instances
2. **GraphQL API**: Modern API interface alongside JSON-RPC
3. **Event Streaming**: Real-time event publication via WebSockets
4. **Clustering Support**: Multi-node deployments for high availability
5. **AI-Powered Routing**: Machine learning for optimal peer selection
6. **Cross-Chain Integration**: Support for multiple blockchain networks

### Scalability Roadmap

```
Phase 1: Single Node Optimization
├── Connection pooling improvements
├── Memory usage optimization
└── Cache efficiency enhancements

Phase 2: Multi-Node Clustering
├── Distributed state management
├── Load balancing algorithms
└── Automatic failover systems

Phase 3: Global Network Integration
├── Geographic routing optimization
├── CDN-like content caching
└── Cross-region data replication
```

---

This architecture provides the foundation for a robust, scalable, and community-focused P2P networking solution. The design emphasizes fault tolerance, performance, and ease of operation while maintaining the security and decentralization principles of the underlying Diode network protocol.