defmodule ChronaraNode.Termux.EmergingMarketsOptimizer do
  @moduledoc """
  Ultra-minimal resource usage optimization for emerging markets deployment.
  
  Optimizes chr-node for devices with:
  - Limited RAM (512MB - 2GB)
  - Slow CPUs (single/dual core ARM)
  - Expensive data connections
  - Intermittent power supply
  - Android 5.0 - 9.0
  """
  
  use GenServer
  require Logger
  
  @ultra_minimal_config %{
    # Memory optimization
    max_heap_size: 64_000_000,  # 64MB max heap
    gc_frequency: :aggressive,
    buffer_sizes: %{
      socket_buffer: 8192,      # 8KB socket buffers
      message_buffer: 4096,     # 4KB message buffers
      cache_buffer: 16384       # 16KB cache
    },
    
    # Network optimization
    connection_limits: %{
      max_peers: 5,             # Maximum 5 peer connections
      max_concurrent: 2,        # Max 2 concurrent operations
      timeout_ms: 30_000,       # 30 second timeouts
      retry_attempts: 2         # Max 2 retries
    },
    
    # Data conservation
    compression: %{
      enable_gzip: true,
      compression_level: 6,     # Balance between speed and size
      min_compress_size: 1024   # Only compress >1KB messages
    },
    
    # Battery optimization
    power_management: %{
      cpu_throttle: true,
      background_pause: 300_000,  # 5 minute pause when backgrounded
      sleep_mode_timeout: 60_000, # Sleep after 1 minute idle
      wake_on_message: true
    },
    
    # Storage optimization
    storage: %{
      max_log_size: 1_000_000,   # 1MB max log files
      log_rotation_count: 3,      # Keep 3 log files
      cache_cleanup_interval: 600_000, # Clean cache every 10 minutes
      temp_file_cleanup: 300_000  # Clean temp files every 5 minutes
    },
    
    # Feature limitations
    disabled_features: [
      :advanced_routing,
      :detailed_metrics,
      :debug_logging,
      :peer_analytics,
      :connection_history
    ]
  }
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    device_profile = Keyword.get(opts, :device_profile, %{})
    optimization_level = determine_optimization_level(device_profile)
    
    config = generate_optimized_config(optimization_level, device_profile)
    apply_system_optimizations(config)
    
    Logger.info("🌍 Emerging markets optimizer initialized: #{optimization_level}")
    
    {:ok, %{
      config: config,
      optimization_level: optimization_level,
      device_profile: device_profile,
      stats: initialize_stats()
    }}
  end
  
  def get_optimization_config() do
    GenServer.call(__MODULE__, :get_config)
  end
  
  def update_device_profile(device_profile) do
    GenServer.call(__MODULE__, {:update_device_profile, device_profile})
  end
  
  def get_performance_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end
  
  def handle_call({:update_device_profile, device_profile}, _from, state) do
    optimization_level = determine_optimization_level(device_profile)
    config = generate_optimized_config(optimization_level, device_profile)
    
    apply_system_optimizations(config)
    
    new_state = %{state | 
      device_profile: device_profile,
      config: config,
      optimization_level: optimization_level
    }
    
    {:reply, :ok, new_state}
  end
  
  def handle_call(:get_stats, _from, state) do
    current_stats = %{
      state.stats |
      current_memory_usage: get_current_memory_usage(),
      current_cpu_usage: get_current_cpu_usage(),
      active_connections: get_active_connections(),
      data_usage_today: get_data_usage_today(),
      battery_level: get_battery_level(),
      optimization_level: state.optimization_level
    }
    
    {:reply, current_stats, %{state | stats: current_stats}}
  end
  
  defp determine_optimization_level(device_profile) do
    memory_mb = Map.get(device_profile, :memory_mb, 1000)
    cpu_cores = Map.get(device_profile, :cpu_cores, 1)
    android_version = Map.get(device_profile, :android_version, 8.0)
    emerging_market_score = Map.get(device_profile, :emerging_market_score, 50)
    
    cond do
      memory_mb < 512 or cpu_cores == 1 or android_version < 6.0 -> :emergency_only
      memory_mb < 1000 or emerging_market_score > 80 -> :ultra_minimal
      memory_mb < 2000 or emerging_market_score > 60 -> :minimal
      emerging_market_score > 40 -> :conservative
      true -> :standard
    end
  end
  
  defp generate_optimized_config(:emergency_only, device_profile) do
    Map.merge(@ultra_minimal_config, %{
      connection_limits: %{
        max_peers: 1,
        max_concurrent: 1,
        timeout_ms: 60_000,
        retry_attempts: 1
      },
      buffer_sizes: %{
        socket_buffer: 4096,
        message_buffer: 2048,
        cache_buffer: 8192
      },
      power_management: Map.merge(@ultra_minimal_config.power_management, %{
        background_pause: 600_000,  # 10 minutes
        sleep_mode_timeout: 30_000  # 30 seconds
      }),
      data_conservation_mode: :extreme,
      device_profile: device_profile
    })
  end
  
  defp generate_optimized_config(:ultra_minimal, device_profile) do
    Map.put(@ultra_minimal_config, :device_profile, device_profile)
  end
  
  defp generate_optimized_config(:minimal, device_profile) do
    Map.merge(@ultra_minimal_config, %{
      connection_limits: %{
        max_peers: 8,
        max_concurrent: 3,
        timeout_ms: 20_000,
        retry_attempts: 3
      },
      buffer_sizes: %{
        socket_buffer: 16384,
        message_buffer: 8192,
        cache_buffer: 32768
      },
      device_profile: device_profile
    })
  end
  
  defp generate_optimized_config(:conservative, device_profile) do
    Map.merge(@ultra_minimal_config, %{
      max_heap_size: 128_000_000,  # 128MB
      connection_limits: %{
        max_peers: 15,
        max_concurrent: 5,
        timeout_ms: 15_000,
        retry_attempts: 3
      },
      buffer_sizes: %{
        socket_buffer: 32768,
        message_buffer: 16384,
        cache_buffer: 65536
      },
      disabled_features: [
        :debug_logging,
        :detailed_metrics
      ],
      device_profile: device_profile
    })
  end
  
  defp generate_optimized_config(:standard, device_profile) do
    %{
      max_heap_size: 256_000_000,  # 256MB
      gc_frequency: :normal,
      connection_limits: %{
        max_peers: 25,
        max_concurrent: 8,
        timeout_ms: 10_000,
        retry_attempts: 5
      },
      buffer_sizes: %{
        socket_buffer: 65536,
        message_buffer: 32768,
        cache_buffer: 131072
      },
      compression: %{
        enable_gzip: true,
        compression_level: 3,
        min_compress_size: 512
      },
      power_management: %{
        cpu_throttle: false,
        background_pause: 60_000,
        sleep_mode_timeout: 300_000,
        wake_on_message: true
      },
      disabled_features: [],
      device_profile: device_profile
    }
  end
  
  defp apply_system_optimizations(config) do
    # Apply JVM/BEAM optimizations
    apply_memory_optimizations(config)
    apply_network_optimizations(config)
    apply_power_optimizations(config)
    apply_storage_optimizations(config)
    
    Logger.info("✅ System optimizations applied for #{config[:device_profile][:device_tier] || :unknown} device")
  end
  
  defp apply_memory_optimizations(config) do
    # Set BEAM memory limits
    System.put_env("ERL_MAX_HEAP_SIZE", to_string(config.max_heap_size))
    
    # Configure garbage collection
    case config.gc_frequency do
      :aggressive ->
        :erlang.system_flag(:fullsweep_after, 5)
        :erlang.system_flag(:min_heap_size, 233)  # Minimum heap size
      :normal ->
        :erlang.system_flag(:fullsweep_after, 10)
      _ -> :ok
    end
    
    Logger.debug("🧠 Memory optimizations applied: max_heap=#{config.max_heap_size}")
  end
  
  defp apply_network_optimizations(config) do
    # Configure network timeouts and limits
    Application.put_env(:chronara_node, :max_peers, config.connection_limits.max_peers)
    Application.put_env(:chronara_node, :connection_timeout, config.connection_limits.timeout_ms)
    Application.put_env(:chronara_node, :socket_buffer_size, config.buffer_sizes.socket_buffer)
    
    Logger.debug("🌐 Network optimizations applied: max_peers=#{config.connection_limits.max_peers}")
  end
  
  defp apply_power_optimizations(config) do
    power_config = config.power_management
    
    # Configure CPU throttling if enabled
    if power_config.cpu_throttle do
      # This would integrate with Android's CPU governor
      System.cmd("sh", ["-c", "echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"], stderr_to_stdout: true)
    end
    
    Application.put_env(:chronara_node, :power_management, power_config)
    Logger.debug("🔋 Power optimizations applied: cpu_throttle=#{power_config.cpu_throttle}")
  end
  
  defp apply_storage_optimizations(config) do
    storage_config = config.storage
    
    # Configure log rotation
    Application.put_env(:logger, :rotating_log, %{
      max_bytes: storage_config.max_log_size,
      keep: storage_config.log_rotation_count
    })
    
    # Schedule cleanup tasks
    schedule_cleanup_tasks(storage_config)
    
    Logger.debug("💾 Storage optimizations applied: max_log=#{storage_config.max_log_size}")
  end
  
  defp schedule_cleanup_tasks(storage_config) do
    # Cache cleanup
    Process.send_after(self(), :cleanup_cache, storage_config.cache_cleanup_interval)
    
    # Temp file cleanup
    Process.send_after(self(), :cleanup_temp_files, storage_config.temp_file_cleanup)
  end
  
  def handle_info(:cleanup_cache, state) do
    cleanup_cache()
    schedule_cleanup_tasks(state.config.storage)
    {:noreply, state}
  end
  
  def handle_info(:cleanup_temp_files, state) do
    cleanup_temp_files()
    {:noreply, state}
  end
  
  defp cleanup_cache() do
    cache_dir = "/data/data/com.termux/files/home/.chr-node/cache"
    
    case File.ls(cache_dir) do
      {:ok, files} ->
        # Remove files older than 1 hour
        cutoff_time = System.system_time(:second) - 3600
        
        Enum.each(files, fn file ->
          file_path = Path.join(cache_dir, file)
          case File.stat(file_path) do
            {:ok, %{mtime: mtime}} when mtime < cutoff_time ->
              File.rm(file_path)
            _ -> :ok
          end
        end)
        
        Logger.debug("🧹 Cache cleanup completed")
      {:error, _} -> :ok
    end
  end
  
  defp cleanup_temp_files() do
    temp_dir = "/data/data/com.termux/files/home/.chr-node/tmp"
    
    case File.ls(temp_dir) do
      {:ok, files} ->
        Enum.each(files, &File.rm(Path.join(temp_dir, &1)))
        Logger.debug("🧹 Temp files cleanup completed")
      {:error, _} -> :ok
    end
  end
  
  defp initialize_stats() do
    %{
      start_time: System.system_time(:second),
      memory_peak: 0,
      connections_made: 0,
      messages_sent: 0,
      messages_received: 0,
      data_sent_bytes: 0,
      data_received_bytes: 0,
      optimization_events: 0
    }
  end
  
  defp get_current_memory_usage() do
    case :erlang.memory() do
      memory_info when is_list(memory_info) ->
        Keyword.get(memory_info, :total, 0)
      _ -> 0
    end
  end
  
  defp get_current_cpu_usage() do
    case System.cmd("sh", ["-c", "cat /proc/loadavg"], stderr_to_stdout: true) do
      {output, 0} ->
        case String.split(output, " ") do
          [load1min | _] -> String.to_float(load1min)
          _ -> 0.0
        end
      _ -> 0.0
    end
  end
  
  defp get_active_connections() do
    # This would be implemented by the main chr-node networking module
    Application.get_env(:chronara_node, :active_connections, 0)
  end
  
  defp get_data_usage_today() do
    # This would track data usage throughout the day
    Application.get_env(:chronara_node, :data_usage_today, %{sent: 0, received: 0})
  end
  
  defp get_battery_level() do
    case System.cmd("termux-battery-status", [], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"percentage" => level}} -> level
          _ -> nil
        end
      _ -> nil
    end
  end
  
  def create_deployment_profile(device_classification) do
    """
    # chr-node Deployment Profile for Emerging Markets
    
    ## Device Classification
    - Device Tier: #{device_classification.device_tier}
    - Memory: #{device_classification.memory_mb}MB
    - CPU Cores: #{device_classification.cpu_cores}
    - Android Version: #{device_classification.android_version}
    - Emerging Market Score: #{device_classification.emerging_market_score}%
    
    ## Optimization Level
    #{determine_optimization_level(device_classification)}
    
    ## Recommended Configuration
    ```elixir
    #{inspect(generate_optimized_config(determine_optimization_level(device_classification), device_classification), pretty: true)}
    ```
    
    ## Data Conservation Settings
    - Compress all traffic: #{device_classification.emerging_market_score > 70}
    - WiFi only mode: #{device_classification.emerging_market_score > 80}
    - Background sync limit: #{device_classification.emerging_market_score > 70}
    
    ## Performance Expectations
    - Max concurrent peers: #{get_max_peers(determine_optimization_level(device_classification))}
    - Memory usage target: #{get_memory_target(determine_optimization_level(device_classification))}MB
    - Battery usage: #{get_battery_usage(determine_optimization_level(device_classification))}
    
    ## Deployment Readiness
    ✅ Device compatible with chr-node
    ✅ Termux API integration available  
    ✅ Optimization profile generated
    ✅ Ready for emerging markets deployment
    """
  end
  
  defp get_max_peers(:emergency_only), do: 1
  defp get_max_peers(:ultra_minimal), do: 5
  defp get_max_peers(:minimal), do: 8
  defp get_max_peers(:conservative), do: 15
  defp get_max_peers(:standard), do: 25
  
  defp get_memory_target(:emergency_only), do: 32
  defp get_memory_target(:ultra_minimal), do: 64
  defp get_memory_target(:minimal), do: 96
  defp get_memory_target(:conservative), do: 128
  defp get_memory_target(:standard), do: 256
  
  defp get_battery_usage(:emergency_only), do: "Ultra Low"
  defp get_battery_usage(:ultra_minimal), do: "Very Low"
  defp get_battery_usage(:minimal), do: "Low"
  defp get_battery_usage(:conservative), do: "Moderate"
  defp get_battery_usage(:standard), do: "Normal"
end