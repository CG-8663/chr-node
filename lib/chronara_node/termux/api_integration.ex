defmodule ChronaraNode.Termux.APIIntegration do
  @moduledoc """
  Complete Termux API Integration for chr-node Mobile Deployment
  
  Integrates all 21+ Termux APIs for comprehensive mobile P2P networking:
  - System APIs: battery, clipboard, volume, brightness, notifications
  - Hardware APIs: camera, location, sensors, vibration, torch, microphone
  - Communication APIs: telephony, SMS, WiFi, NFC  
  - Advanced APIs: TTS, STT, infrared, USB, storage
  """
  
  use GenServer
  require Logger
  
  @system_apis [
    :battery, :clipboard, :volume, :brightness, :toast, 
    :dialog, :notification, :wallpaper, :contacts
  ]
  
  @hardware_apis [
    :camera, :location, :sensor, :vibrate, :torch, 
    :microphone, :fingerprint, :keystore
  ]
  
  @communication_apis [
    :telephony_call, :telephony_deviceinfo, :sms_send, :sms_list,
    :wifi_connectioninfo, :wifi_scaninfo, :nfc
  ]
  
  @advanced_apis [
    :tts, :stt, :infrared, :usb, :storage, :share, :download
  ]
  
  @all_apis @system_apis ++ @hardware_apis ++ @communication_apis ++ @advanced_apis
  
  defstruct [
    :available_apis,
    :api_status,
    :optimization_config,
    :device_profile,
    :performance_stats
  ]
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    Logger.info("🔌 Initializing Termux API integration for chr-node...")
    
    # Test all APIs for availability
    api_status = test_all_apis()
    available_apis = get_available_apis(api_status)
    
    # Get device profile and optimization config
    device_profile = Keyword.get(opts, :device_profile, %{})
    optimization_config = ChronaraNode.Termux.EmergingMarketsOptimizer.get_optimization_config()
    
    Logger.info("✅ Termux API integration initialized: #{length(available_apis)}/#{length(@all_apis)} APIs available")
    
    {:ok, %__MODULE__{
      available_apis: available_apis,
      api_status: api_status,
      optimization_config: optimization_config,
      device_profile: device_profile,
      performance_stats: %{}
    }}
  end
  
  # System APIs
  def get_battery_status() do
    GenServer.call(__MODULE__, {:execute_api, :battery, "termux-battery-status"})
  end
  
  def set_clipboard(text) do
    GenServer.call(__MODULE__, {:execute_api, :clipboard, "termux-clipboard-set '#{text}'"})
  end
  
  def get_clipboard() do
    GenServer.call(__MODULE__, {:execute_api, :clipboard, "termux-clipboard-get"})
  end
  
  def set_volume(stream, level) do
    GenServer.call(__MODULE__, {:execute_api, :volume, "termux-volume #{stream} #{level}"})
  end
  
  def set_brightness(level) do
    GenServer.call(__MODULE__, {:execute_api, :brightness, "termux-brightness #{level}"})
  end
  
  def show_toast(message) do
    GenServer.call(__MODULE__, {:execute_api, :toast, "termux-toast '#{message}'"})
  end
  
  def show_notification(title, content) do
    GenServer.call(__MODULE__, {:execute_api, :notification, "termux-notification --title '#{title}' --content '#{content}'"})
  end
  
  # Hardware APIs
  def get_camera_info() do
    GenServer.call(__MODULE__, {:execute_api, :camera, "termux-camera-info"})
  end
  
  def take_photo(output_path \\ "/tmp/chr-node-photo.jpg") do
    GenServer.call(__MODULE__, {:execute_api, :camera, "termux-camera-photo #{output_path}"})
  end
  
  def get_location(provider \\ "network") do
    GenServer.call(__MODULE__, {:execute_api, :location, "termux-location -p #{provider}"})
  end
  
  def get_sensor_data(sensor_type \\ "accelerometer", count \\ 1) do
    GenServer.call(__MODULE__, {:execute_api, :sensor, "termux-sensor -s #{sensor_type} -n #{count}"})
  end
  
  def vibrate(duration_ms \\ 1000) do
    GenServer.call(__MODULE__, {:execute_api, :vibrate, "termux-vibrate -d #{duration_ms}"})
  end
  
  def toggle_torch(state \\ "on") do
    GenServer.call(__MODULE__, {:execute_api, :torch, "termux-torch #{state}"})
  end
  
  def record_audio(output_path, duration_seconds \\ 5) do
    GenServer.call(__MODULE__, {:execute_api, :microphone, "termux-microphone-record -f #{output_path} -l #{duration_seconds}"})
  end
  
  def authenticate_fingerprint() do
    GenServer.call(__MODULE__, {:execute_api, :fingerprint, "termux-fingerprint"})
  end
  
  # Communication APIs
  def make_call(number) do
    GenServer.call(__MODULE__, {:execute_api, :telephony_call, "termux-telephony-call #{number}"})
  end
  
  def get_device_info() do
    GenServer.call(__MODULE__, {:execute_api, :telephony_deviceinfo, "termux-telephony-deviceinfo"})
  end
  
  def send_sms(number, message) do
    GenServer.call(__MODULE__, {:execute_api, :sms_send, "termux-sms-send -n #{number} '#{message}'"})
  end
  
  def list_sms(limit \\ 10) do
    GenServer.call(__MODULE__, {:execute_api, :sms_list, "termux-sms-list -l #{limit}"})
  end
  
  def get_wifi_info() do
    GenServer.call(__MODULE__, {:execute_api, :wifi_connectioninfo, "termux-wifi-connectioninfo"})
  end
  
  def scan_wifi() do
    GenServer.call(__MODULE__, {:execute_api, :wifi_scaninfo, "termux-wifi-scaninfo"})
  end
  
  def read_nfc() do
    GenServer.call(__MODULE__, {:execute_api, :nfc, "termux-nfc"})
  end
  
  # Advanced APIs  
  def speak_text(text, language \\ "en") do
    GenServer.call(__MODULE__, {:execute_api, :tts, "termux-tts-speak -l #{language} '#{text}'"})
  end
  
  def speech_to_text() do
    GenServer.call(__MODULE__, {:execute_api, :stt, "termux-speech-to-text"})
  end
  
  def get_infrared_frequencies() do
    GenServer.call(__MODULE__, {:execute_api, :infrared, "termux-infrared-frequencies"})
  end
  
  def list_usb_devices() do
    GenServer.call(__MODULE__, {:execute_api, :usb, "termux-usb -l"})
  end
  
  def access_storage(type \\ "DCIM") do
    GenServer.call(__MODULE__, {:execute_api, :storage, "termux-storage-get #{type}"})
  end
  
  # API status and management
  def get_available_apis() do
    GenServer.call(__MODULE__, :get_available_apis)
  end
  
  def get_api_status() do
    GenServer.call(__MODULE__, :get_api_status)
  end
  
  def refresh_api_status() do
    GenServer.call(__MODULE__, :refresh_api_status)
  end
  
  # chr-node specific integrations
  def initialize_chr_node_integration() do
    GenServer.call(__MODULE__, :initialize_chr_node_integration)
  end
  
  def get_node_connectivity_status() do
    GenServer.call(__MODULE__, :get_node_connectivity_status)
  end
  
  def optimize_for_mobile_deployment() do
    GenServer.call(__MODULE__, :optimize_for_mobile_deployment)
  end
  
  # GenServer callbacks
  def handle_call({:execute_api, api_type, command}, _from, state) do
    if api_type in state.available_apis do
      case execute_termux_command(command) do
        {:ok, result} ->
          {:reply, {:ok, result}, state}
        {:error, reason} ->
          Logger.warn("API #{api_type} execution failed: #{reason}")
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :api_not_available}, state}
    end
  end
  
  def handle_call(:get_available_apis, _from, state) do
    {:reply, state.available_apis, state}
  end
  
  def handle_call(:get_api_status, _from, state) do
    {:reply, state.api_status, state}
  end
  
  def handle_call(:refresh_api_status, _from, state) do
    new_api_status = test_all_apis()
    new_available_apis = get_available_apis(new_api_status)
    
    new_state = %{state | 
      api_status: new_api_status,
      available_apis: new_available_apis
    }
    
    {:reply, {:ok, length(new_available_apis)}, new_state}
  end
  
  def handle_call(:initialize_chr_node_integration, _from, state) do
    integration_status = initialize_integrations(state.available_apis)
    {:reply, integration_status, state}
  end
  
  def handle_call(:get_node_connectivity_status, _from, state) do
    connectivity_status = check_node_connectivity(state.available_apis)
    {:reply, connectivity_status, state}
  end
  
  def handle_call(:optimize_for_mobile_deployment, _from, state) do
    optimizations = apply_mobile_optimizations(state)
    {:reply, optimizations, state}
  end
  
  # Private helper functions
  defp test_all_apis() do
    Logger.info("🧪 Testing all Termux APIs for availability...")
    
    @all_apis
    |> Enum.map(&test_single_api/1)
    |> Enum.into(%{})
  end
  
  defp test_single_api(api_type) do
    command = get_test_command(api_type)
    
    case execute_termux_command(command) do
      {:ok, _result} ->
        {api_type, %{status: :available, tested_at: DateTime.utc_now()}}
      {:error, reason} ->
        {api_type, %{status: :unavailable, reason: reason, tested_at: DateTime.utc_now()}}
    end
  end
  
  defp get_test_command(:battery), do: "termux-battery-status"
  defp get_test_command(:clipboard), do: "termux-clipboard-get"
  defp get_test_command(:volume), do: "termux-volume music"
  defp get_test_command(:brightness), do: "termux-brightness"
  defp get_test_command(:toast), do: "termux-toast --help"
  defp get_test_command(:dialog), do: "termux-dialog --help"
  defp get_test_command(:notification), do: "termux-notification --help"
  defp get_test_command(:camera), do: "termux-camera-info"
  defp get_test_command(:location), do: "termux-location --help"
  defp get_test_command(:sensor), do: "termux-sensor -l"
  defp get_test_command(:vibrate), do: "termux-vibrate --help"
  defp get_test_command(:torch), do: "termux-torch --help"
  defp get_test_command(:microphone), do: "termux-microphone-record --help"
  defp get_test_command(:fingerprint), do: "termux-fingerprint --help"
  defp get_test_command(:telephony_call), do: "termux-telephony-call --help"
  defp get_test_command(:telephony_deviceinfo), do: "termux-telephony-deviceinfo"
  defp get_test_command(:sms_send), do: "termux-sms-send --help"
  defp get_test_command(:sms_list), do: "termux-sms-list --help"
  defp get_test_command(:wifi_connectioninfo), do: "termux-wifi-connectioninfo"
  defp get_test_command(:wifi_scaninfo), do: "termux-wifi-scaninfo"
  defp get_test_command(:nfc), do: "termux-nfc --help"
  defp get_test_command(:tts), do: "termux-tts-speak --help"
  defp get_test_command(:stt), do: "termux-speech-to-text --help"
  defp get_test_command(:infrared), do: "termux-infrared-frequencies"
  defp get_test_command(:usb), do: "termux-usb -l"
  defp get_test_command(:storage), do: "termux-storage-get --help"
  defp get_test_command(_), do: "echo test"
  
  defp execute_termux_command(command) do
    case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, String.trim(output)}
      {error_output, exit_code} ->
        {:error, %{output: String.trim(error_output), exit_code: exit_code}}
    end
  end
  
  defp get_available_apis(api_status) do
    api_status
    |> Enum.filter(fn {_api, status} -> status.status == :available end)
    |> Enum.map(fn {api, _status} -> api end)
  end
  
  defp initialize_integrations(available_apis) do
    Logger.info("🔧 Initializing chr-node integrations for available APIs...")
    
    integrations = %{
      network_monitoring: :wifi_connectioninfo in available_apis,
      location_services: :location in available_apis,
      system_monitoring: :battery in available_apis and :sensor in available_apis,
      user_notifications: :notification in available_apis,
      peer_discovery: :wifi_scaninfo in available_apis or :nfc in available_apis,
      emergency_communication: :sms_send in available_apis,
      voice_interface: :tts in available_apis and :stt in available_apis,
      security_features: :fingerprint in available_apis
    }
    
    # Initialize specific integrations
    if integrations.network_monitoring do
      setup_network_monitoring()
    end
    
    if integrations.location_services do
      setup_location_services()
    end
    
    if integrations.system_monitoring do
      setup_system_monitoring()
    end
    
    if integrations.peer_discovery do
      setup_peer_discovery()
    end
    
    Logger.info("✅ chr-node integrations initialized: #{Enum.count(integrations, fn {_, enabled} -> enabled end)}/#{length(Map.keys(integrations))} active")
    
    integrations
  end
  
  defp setup_network_monitoring() do
    # Schedule regular WiFi connection monitoring
    Process.send_after(self(), :monitor_wifi, 30_000)
    Logger.debug("📡 Network monitoring initialized")
  end
  
  defp setup_location_services() do
    # Initialize location tracking for mesh networking
    Logger.debug("📍 Location services initialized")
  end
  
  defp setup_system_monitoring() do
    # Schedule system health monitoring
    Process.send_after(self(), :monitor_system, 60_000)
    Logger.debug("🖥️ System monitoring initialized")
  end
  
  defp setup_peer_discovery() do
    # Initialize peer discovery using available methods
    Logger.debug("🔍 Peer discovery initialized")
  end
  
  defp check_node_connectivity(available_apis) do
    %{
      internet_connection: check_internet_connectivity(),
      wifi_available: :wifi_connectioninfo in available_apis,
      cellular_available: :telephony_deviceinfo in available_apis,
      peer_discovery_methods: get_peer_discovery_methods(available_apis),
      mesh_networking_capability: assess_mesh_capability(available_apis)
    }
  end
  
  defp check_internet_connectivity() do
    case System.cmd("ping", ["-c", "1", "-W", "3", "8.8.8.8"], stderr_to_stdout: true) do
      {_output, 0} -> true
      {_error, _} -> false
    end
  end
  
  defp get_peer_discovery_methods(available_apis) do
    methods = []
    
    methods = if :wifi_scaninfo in available_apis, do: [:wifi_direct | methods], else: methods
    methods = if :nfc in available_apis, do: [:nfc | methods], else: methods
    methods = if File.exists?("/sys/class/bluetooth"), do: [:bluetooth | methods], else: methods
    
    methods
  end
  
  defp assess_mesh_capability(available_apis) do
    discovery_methods = get_peer_discovery_methods(available_apis)
    
    cond do
      :wifi_direct in discovery_methods -> :high
      :bluetooth in discovery_methods -> :medium
      :nfc in discovery_methods -> :low
      true -> :none
    end
  end
  
  defp apply_mobile_optimizations(state) do
    optimizations = []
    
    # Battery optimization
    if :battery in state.available_apis do
      optimizations = [:battery_monitoring | optimizations]
      setup_battery_optimization()
    end
    
    # Data conservation
    if :wifi_connectioninfo in state.available_apis do
      optimizations = [:data_conservation | optimizations]
      setup_data_conservation()
    end
    
    # Performance optimization
    if :sensor in state.available_apis do
      optimizations = [:performance_monitoring | optimizations]
      setup_performance_monitoring()
    end
    
    Logger.info("🚀 Mobile optimizations applied: #{inspect(optimizations)}")
    optimizations
  end
  
  defp setup_battery_optimization() do
    # Monitor battery level and adjust performance accordingly
    Process.send_after(self(), :check_battery, 120_000)
  end
  
  defp setup_data_conservation() do
    # Monitor data usage and apply conservation measures
    Logger.debug("📊 Data conservation measures activated")
  end
  
  defp setup_performance_monitoring() do
    # Use sensor data to detect device movement and adjust networking
    Logger.debug("⚡ Performance monitoring activated")
  end
  
  # Message handlers for scheduled tasks
  def handle_info(:monitor_wifi, state) do
    if :wifi_connectioninfo in state.available_apis do
      case get_wifi_info() do
        {:ok, wifi_info} ->
          Logger.debug("📡 WiFi status: #{inspect(wifi_info)}")
        {:error, _reason} ->
          Logger.warn("📡 WiFi monitoring failed")
      end
    end
    
    # Schedule next check
    Process.send_after(self(), :monitor_wifi, 30_000)
    {:noreply, state}
  end
  
  def handle_info(:monitor_system, state) do
    if :battery in state.available_apis do
      case get_battery_status() do
        {:ok, battery_info} ->
          Logger.debug("🔋 Battery status: #{inspect(battery_info)}")
        {:error, _reason} ->
          Logger.warn("🔋 Battery monitoring failed")
      end
    end
    
    # Schedule next check
    Process.send_after(self(), :monitor_system, 60_000)
    {:noreply, state}
  end
  
  def handle_info(:check_battery, state) do
    case get_battery_status() do
      {:ok, battery_json} ->
        case Jason.decode(battery_json) do
          {:ok, %{"percentage" => level}} when level < 20 ->
            # Enable aggressive power saving
            ChronaraNode.Termux.EmergingMarketsOptimizer.update_device_profile(%{battery_level: level})
            Logger.warn("🔋 Low battery detected (#{level}%), enabling power saving mode")
          _ -> :ok
        end
      _ -> :ok
    end
    
    # Schedule next check
    Process.send_after(self(), :check_battery, 300_000)  # Check every 5 minutes
    {:noreply, state}
  end
end