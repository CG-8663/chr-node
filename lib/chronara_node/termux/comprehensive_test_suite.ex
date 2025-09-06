defmodule ChronaraNode.Termux.ComprehensiveTestSuite do
  @moduledoc """
  Complete Termux API Testing Suite for chr-node Mobile Deployment
  
  Tests all 21+ Termux APIs for emerging markets rollout validation.
  Generates device classification reports for deployment optimization.
  """
  
  use GenServer
  require Logger
  
  @test_apis [
    # System APIs
    {:battery, "termux-battery-status"},
    {:clipboard, "termux-clipboard-get"},
    {:volume, "termux-volume music 10"},
    {:brightness, "termux-brightness 128"},
    {:toast, "termux-toast 'chr-node test'"},
    {:dialog, "termux-dialog text -t 'chr-node'"},
    {:notification, "termux-notification --content 'chr-node active'"},
    
    # Hardware APIs
    {:camera_info, "termux-camera-info"},
    {:camera_photo, "termux-camera-photo /data/data/com.termux/files/home/test.jpg"},
    {:location, "termux-location -p network"},
    {:sensor, "termux-sensor -s accelerometer -n 1"},
    {:vibrate, "termux-vibrate -d 500"},
    {:torch, "termux-torch on"},
    {:microphone, "termux-microphone-record -f /tmp/test.wav -l 1"},
    {:fingerprint, "termux-fingerprint"},
    
    # Communication APIs
    {:telephony_call, "termux-telephony-call +1234567890"},
    {:sms_send, "termux-sms-send -n +1234567890 'test'"},
    {:telephony_deviceinfo, "termux-telephony-deviceinfo"},
    {:wifi_connectioninfo, "termux-wifi-connectioninfo"},
    {:wifi_scaninfo, "termux-wifi-scaninfo"},
    {:nfc, "termux-nfc"},
    
    # Advanced APIs
    {:tts, "termux-tts-speak 'chr-node initialized'"},
    {:stt, "termux-speech-to-text"},
    {:infrared, "termux-infrared-frequencies"},
    {:usb, "termux-usb -l"},
    {:storage, "termux-storage-get DCIM"}
  ]
  
  @device_classification_tests [
    {:cpu_info, "cat /proc/cpuinfo"},
    {:memory_info, "cat /proc/meminfo"},
    {:network_interfaces, "ip addr show"},
    {:android_version, "getprop ro.build.version.release"},
    {:device_model, "getprop ro.product.model"},
    {:available_sensors, "termux-sensor -l"},
    {:battery_capacity, "cat /sys/class/power_supply/battery/capacity"},
    {:storage_space, "df -h /data"},
    {:cpu_cores, "nproc"},
    {:architecture, "uname -m"}
  ]
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("Starting Termux Comprehensive Test Suite for chr-node mobile deployment")
    {:ok, %{test_results: %{}, device_profile: %{}}}
  end
  
  def run_full_test_suite() do
    GenServer.call(__MODULE__, :run_full_suite, 60_000)
  end
  
  def get_device_classification() do
    GenServer.call(__MODULE__, :get_device_classification)
  end
  
  def handle_call(:run_full_suite, _from, state) do
    Logger.info("🚀 Starting comprehensive Termux API testing for emerging markets deployment")
    
    # Phase 1: Device Classification
    device_profile = run_device_classification()
    Logger.info("📱 Device classification complete: #{inspect(device_profile)}")
    
    # Phase 2: API Availability Testing
    api_results = test_all_apis()
    Logger.info("🔧 API testing complete: #{length(api_results)} APIs tested")
    
    # Phase 3: Performance Benchmarking
    performance_metrics = run_performance_tests()
    Logger.info("⚡ Performance benchmarking complete")
    
    # Phase 4: Emerging Markets Optimization
    optimization_config = generate_optimization_config(device_profile, api_results)
    Logger.info("🌍 Emerging markets configuration generated")
    
    complete_report = %{
      device_profile: device_profile,
      api_results: api_results,
      performance_metrics: performance_metrics,
      optimization_config: optimization_config,
      test_timestamp: DateTime.utc_now(),
      deployment_recommendation: determine_deployment_tier(device_profile, performance_metrics)
    }
    
    save_test_report(complete_report)
    
    {:reply, complete_report, %{state | test_results: api_results, device_profile: device_profile}}
  end
  
  def handle_call(:get_device_classification, _from, state) do
    {:reply, state.device_profile, state}
  end
  
  defp run_device_classification() do
    Logger.info("🔍 Running device classification tests...")
    
    results = Enum.map(@device_classification_tests, fn {test_name, command} ->
      case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
        {output, 0} ->
          {test_name, %{status: :success, output: String.trim(output)}}
        {error_output, _exit_code} ->
          {test_name, %{status: :error, output: String.trim(error_output)}}
      end
    end)
    |> Enum.into(%{})
    
    # Extract key device characteristics
    device_tier = classify_device_tier(results)
    network_capabilities = extract_network_capabilities(results)
    resource_constraints = analyze_resource_constraints(results)
    
    %{
      raw_results: results,
      device_tier: device_tier,
      network_capabilities: network_capabilities,
      resource_constraints: resource_constraints,
      emerging_market_score: calculate_emerging_market_score(results)
    }
  end
  
  defp test_all_apis() do
    Logger.info("🧪 Testing all #{length(@test_apis)} Termux APIs...")
    
    Enum.map(@test_apis, fn {api_name, command} ->
      Logger.debug("Testing #{api_name}: #{command}")
      
      case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
        {output, 0} ->
          {api_name, %{
            status: :available,
            command: command,
            output: String.trim(output),
            response_time: measure_response_time(command)
          }}
        {error_output, exit_code} ->
          {api_name, %{
            status: :unavailable,
            command: command,
            error: String.trim(error_output),
            exit_code: exit_code,
            reason: categorize_failure_reason(error_output)
          }}
      end
    end)
    |> Enum.into(%{})
  end
  
  defp run_performance_tests() do
    Logger.info("⚡ Running performance benchmarks...")
    
    %{
      network_latency: measure_network_latency(),
      disk_io: measure_disk_performance(),
      memory_usage: measure_memory_usage(),
      cpu_performance: measure_cpu_performance(),
      battery_drain: measure_battery_drain_rate()
    }
  end
  
  defp generate_optimization_config(device_profile, api_results) do
    available_apis = api_results
    |> Enum.filter(fn {_api, result} -> result.status == :available end)
    |> Enum.map(fn {api, _} -> api end)
    
    %{
      # Resource conservation settings
      max_connections: determine_max_connections(device_profile),
      polling_intervals: optimize_polling_intervals(device_profile),
      cache_sizes: optimize_cache_sizes(device_profile),
      
      # Feature availability
      available_features: available_apis,
      fallback_strategies: generate_fallback_strategies(api_results),
      
      # Emerging markets specific
      data_conservation: generate_data_conservation_config(device_profile),
      offline_capabilities: determine_offline_capabilities(available_apis),
      mesh_networking: configure_mesh_networking(available_apis),
      
      # Security adaptations
      security_level: determine_security_level(device_profile),
      encryption_settings: optimize_encryption_settings(device_profile)
    }
  end
  
  defp classify_device_tier(results) do
    memory_mb = extract_memory_mb(results[:memory_info][:output] || "")
    cpu_cores = String.to_integer(results[:cpu_cores][:output] || "1")
    android_version = results[:android_version][:output] || "0"
    
    cond do
      memory_mb >= 4000 and cpu_cores >= 4 -> :high_end
      memory_mb >= 2000 and cpu_cores >= 2 -> :mid_range
      memory_mb >= 1000 -> :low_end
      true -> :ultra_low_end
    end
  end
  
  defp extract_network_capabilities(results) do
    interfaces = results[:network_interfaces][:output] || ""
    
    %{
      has_wifi: String.contains?(interfaces, "wlan"),
      has_cellular: String.contains?(interfaces, "rmnet") or String.contains?(interfaces, "ccmni"),
      has_bluetooth: File.exists?("/sys/class/bluetooth"),
      interface_count: count_network_interfaces(interfaces)
    }
  end
  
  defp analyze_resource_constraints(results) do
    memory_mb = extract_memory_mb(results[:memory_info][:output] || "")
    storage_info = results[:storage_space][:output] || ""
    battery_level = String.to_integer(results[:battery_capacity][:output] || "100")
    
    %{
      memory_constraint: categorize_memory_constraint(memory_mb),
      storage_constraint: categorize_storage_constraint(storage_info),
      battery_constraint: categorize_battery_constraint(battery_level),
      overall_constraint_level: determine_overall_constraint_level(memory_mb, storage_info, battery_level)
    }
  end
  
  defp calculate_emerging_market_score(results) do
    # Score based on typical emerging market device characteristics
    base_score = 50
    
    # Lower android version = higher emerging market probability
    android_version = String.to_float(results[:android_version][:output] || "10.0")
    version_score = max(0, (10.0 - android_version) * 5)
    
    # Lower memory = higher emerging market probability
    memory_mb = extract_memory_mb(results[:memory_info][:output] || "")
    memory_score = cond do
      memory_mb < 1000 -> 30
      memory_mb < 2000 -> 20
      memory_mb < 4000 -> 10
      true -> 0
    end
    
    # Older CPU architecture
    arch = results[:architecture][:output] || ""
    arch_score = if String.contains?(arch, "armv7") or String.contains?(arch, "arm64"), do: 10, else: 0
    
    min(100, base_score + version_score + memory_score + arch_score)
  end
  
  defp determine_deployment_tier(device_profile, performance_metrics) do
    case {device_profile.device_tier, device_profile.emerging_market_score} do
      {:high_end, _} -> :full_node
      {:mid_range, score} when score < 70 -> :standard_lite_node
      {:mid_range, _} -> :optimized_lite_node
      {:low_end, _} -> :minimal_lite_node
      {:ultra_low_end, _} -> :emergency_only_node
    end
  end
  
  defp save_test_report(report) do
    report_path = "/data/data/com.termux/files/home/chr-node-test-report.json"
    
    case Jason.encode(report, pretty: true) do
      {:ok, json} ->
        File.write!(report_path, json)
        Logger.info("📊 Test report saved to #{report_path}")
      {:error, reason} ->
        Logger.error("❌ Failed to save test report: #{reason}")
    end
  end
  
  # Helper functions for measurements and analysis
  defp measure_response_time(command) do
    start_time = System.monotonic_time(:millisecond)
    System.cmd("sh", ["-c", command], stderr_to_stdout: true)
    System.monotonic_time(:millisecond) - start_time
  end
  
  defp measure_network_latency() do
    case System.cmd("ping", ["-c", "3", "8.8.8.8"], stderr_to_stdout: true) do
      {output, 0} ->
        # Extract average latency from ping output
        case Regex.run(~r/avg = ([\d.]+)/, output) do
          [_, latency] -> String.to_float(latency)
          _ -> nil
        end
      _ -> nil
    end
  end
  
  defp measure_disk_performance() do
    # Simple disk write/read test
    test_file = "/tmp/chr-node-disk-test"
    start_time = System.monotonic_time(:millisecond)
    
    File.write!(test_file, String.duplicate("x", 10_000))
    File.read!(test_file)
    File.rm!(test_file)
    
    System.monotonic_time(:millisecond) - start_time
  end
  
  defp measure_memory_usage() do
    case System.cmd("sh", ["-c", "cat /proc/meminfo | grep MemAvailable"], stderr_to_stdout: true) do
      {output, 0} ->
        case Regex.run(~r/MemAvailable:\s+(\d+)\s+kB/, output) do
          [_, mem_kb] -> String.to_integer(mem_kb) * 1024  # Convert to bytes
          _ -> nil
        end
      _ -> nil
    end
  end
  
  defp measure_cpu_performance() do
    # Simple CPU benchmark: calculate primes
    start_time = System.monotonic_time(:millisecond)
    count_primes_up_to(1000)
    System.monotonic_time(:millisecond) - start_time
  end
  
  defp measure_battery_drain_rate() do
    # This would require longer-term monitoring in practice
    case System.cmd("termux-battery-status", [], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, battery_info} -> battery_info
          _ -> %{}
        end
      _ -> %{}
    end
  end
  
  defp count_primes_up_to(n) do
    Enum.count(2..n, &is_prime/1)
  end
  
  defp is_prime(n) when n < 2, do: false
  defp is_prime(2), do: true
  defp is_prime(n) do
    limit = :math.sqrt(n) |> trunc()
    not Enum.any?(2..limit, &(rem(n, &1) == 0))
  end
  
  defp extract_memory_mb(meminfo_output) do
    case Regex.run(~r/MemTotal:\s+(\d+)\s+kB/, meminfo_output) do
      [_, mem_kb] -> div(String.to_integer(mem_kb), 1024)
      _ -> 0
    end
  end
  
  defp count_network_interfaces(interfaces_output) do
    interfaces_output
    |> String.split("\n")
    |> Enum.count(&String.contains?(&1, ": <"))
  end
  
  defp categorize_memory_constraint(memory_mb) do
    cond do
      memory_mb >= 4000 -> :none
      memory_mb >= 2000 -> :low
      memory_mb >= 1000 -> :moderate
      true -> :severe
    end
  end
  
  defp categorize_storage_constraint(storage_info) do
    # Parse available storage from df output
    case Regex.run(~r/(\d+)% /, storage_info) do
      [_, usage_percent] ->
        usage = String.to_integer(usage_percent)
        cond do
          usage < 70 -> :none
          usage < 85 -> :moderate
          true -> :severe
        end
      _ -> :unknown
    end
  end
  
  defp categorize_battery_constraint(battery_level) do
    cond do
      battery_level > 50 -> :none
      battery_level > 20 -> :moderate
      true -> :severe
    end
  end
  
  defp determine_overall_constraint_level(memory_mb, storage_info, battery_level) do
    constraints = [
      categorize_memory_constraint(memory_mb),
      categorize_storage_constraint(storage_info),
      categorize_battery_constraint(battery_level)
    ]
    
    cond do
      :severe in constraints -> :severe
      :moderate in constraints -> :moderate
      true -> :low
    end
  end
  
  defp categorize_failure_reason(error_output) do
    cond do
      String.contains?(error_output, "permission") -> :permission_denied
      String.contains?(error_output, "not found") -> :command_not_found
      String.contains?(error_output, "device") -> :device_not_available
      true -> :unknown
    end
  end
  
  defp determine_max_connections(%{device_tier: :high_end}), do: 50
  defp determine_max_connections(%{device_tier: :mid_range}), do: 25
  defp determine_max_connections(%{device_tier: :low_end}), do: 10
  defp determine_max_connections(%{device_tier: :ultra_low_end}), do: 3
  
  defp optimize_polling_intervals(%{resource_constraints: %{overall_constraint_level: :severe}}), do: %{peer_discovery: 60_000, status_update: 30_000}
  defp optimize_polling_intervals(%{resource_constraints: %{overall_constraint_level: :moderate}}), do: %{peer_discovery: 30_000, status_update: 15_000}
  defp optimize_polling_intervals(_), do: %{peer_discovery: 15_000, status_update: 5_000}
  
  defp optimize_cache_sizes(%{device_tier: :high_end}), do: %{peer_cache: 1000, route_cache: 500}
  defp optimize_cache_sizes(%{device_tier: :mid_range}), do: %{peer_cache: 500, route_cache: 250}
  defp optimize_cache_sizes(%{device_tier: :low_end}), do: %{peer_cache: 100, route_cache: 50}
  defp optimize_cache_sizes(%{device_tier: :ultra_low_end}), do: %{peer_cache: 25, route_cache: 10}
  
  defp generate_fallback_strategies(api_results) do
    %{
      location: if(api_results[:location][:status] != :available, do: :ip_geolocation, else: :gps),
      connectivity: if(api_results[:wifi_connectioninfo][:status] != :available, do: :basic_network_check, else: :wifi_api),
      notifications: if(api_results[:notification][:status] != :available, do: :log_only, else: :native_notifications)
    }
  end
  
  defp generate_data_conservation_config(%{emerging_market_score: score}) when score > 70 do
    %{
      compress_all_traffic: true,
      limit_background_sync: true,
      use_wifi_only: true,
      cache_aggressively: true,
      reduce_telemetry: true
    }
  end
  
  defp generate_data_conservation_config(_) do
    %{
      compress_all_traffic: false,
      limit_background_sync: false,
      use_wifi_only: false,
      cache_aggressively: false,
      reduce_telemetry: false
    }
  end
  
  defp determine_offline_capabilities(available_apis) do
    base_capabilities = [:local_storage, :peer_discovery]
    
    additional_capabilities = []
    |> maybe_add_capability(:mesh_networking, :wifi_scaninfo in available_apis)
    |> maybe_add_capability(:location_services, :location in available_apis)
    |> maybe_add_capability(:sensor_data, :sensor in available_apis)
    
    base_capabilities ++ additional_capabilities
  end
  
  defp maybe_add_capability(list, capability, true), do: [capability | list]
  defp maybe_add_capability(list, _capability, false), do: list
  
  defp configure_mesh_networking(available_apis) do
    %{
      wifi_direct_available: :wifi_scaninfo in available_apis,
      bluetooth_available: File.exists?("/sys/class/bluetooth"),
      nfc_available: :nfc in available_apis,
      recommended_strategy: determine_mesh_strategy(available_apis)
    }
  end
  
  defp determine_mesh_strategy(available_apis) do
    cond do
      :wifi_scaninfo in available_apis -> :wifi_direct_primary
      File.exists?("/sys/class/bluetooth") -> :bluetooth_primary
      :nfc in available_apis -> :nfc_fallback
      true -> :internet_only
    end
  end
  
  defp determine_security_level(%{device_tier: :high_end}), do: :maximum
  defp determine_security_level(%{device_tier: :mid_range}), do: :standard
  defp determine_security_level(_), do: :minimal
  
  defp optimize_encryption_settings(%{device_tier: :ultra_low_end}), do: %{algorithm: :chacha20, key_size: 256}
  defp optimize_encryption_settings(_), do: %{algorithm: :aes_256_gcm, key_size: 256}
end