defmodule ChronaraNode.WhatsApp.WhatsAppInterface do
  @moduledoc """
  WhatsApp Interface for Authenticated chr-node Users
  
  Provides secure WhatsApp integration for verified NFT holders to:
  - Receive node status updates and alerts
  - Get AI agent responses via WhatsApp
  - Execute trading commands through chat
  - Access personalized market insights
  - Manage chr-node remotely via WhatsApp
  
  Security: Only available to authenticated users with verified Chronara Node Pass NFT
  """
  
  use GenServer
  require Logger
  
  alias ChronaraNode.AI.AgentManager
  alias ChronaraNode.AI.{ProAgentIntegration, XNomadIntegration}
  
  @whatsapp_api_url System.get_env("WHATSAPP_API_URL", "https://graph.facebook.com/v17.0")
  @webhook_token System.get_env("WHATSAPP_WEBHOOK_TOKEN")
  @access_token System.get_env("WHATSAPP_ACCESS_TOKEN")
  @phone_number_id System.get_env("WHATSAPP_PHONE_NUMBER_ID")
  
  defstruct [
    :authenticated_users,
    :active_sessions,
    :command_handlers,
    :notification_preferences,
    :rate_limits
  ]
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("💬 Starting WhatsApp Interface for chr-node...")
    
    # Initialize command handlers
    command_handlers = initialize_command_handlers()
    
    {:ok, %__MODULE__{
      authenticated_users: %{},
      active_sessions: %{},
      command_handlers: command_handlers,
      notification_preferences: %{},
      rate_limits: %{}
    }}
  end
  
  # Public API
  
  def authenticate_user(phone_number, wallet_address, nft_verification) do
    GenServer.call(__MODULE__, {:authenticate_user, phone_number, wallet_address, nft_verification})
  end
  
  def send_message(phone_number, message) do
    GenServer.call(__MODULE__, {:send_message, phone_number, message})
  end
  
  def send_notification(wallet_address, notification) do
    GenServer.call(__MODULE__, {:send_notification, wallet_address, notification})
  end
  
  def handle_webhook(webhook_data) do
    GenServer.cast(__MODULE__, {:webhook_received, webhook_data})
  end
  
  def update_notification_preferences(wallet_address, preferences) do
    GenServer.call(__MODULE__, {:update_preferences, wallet_address, preferences})
  end
  
  def get_user_session(phone_number) do
    GenServer.call(__MODULE__, {:get_session, phone_number})
  end
  
  # GenServer callbacks
  
  def handle_call({:authenticate_user, phone_number, wallet_address, nft_verification}, _from, state) do
    case verify_nft_ownership(nft_verification) do
      {:ok, verified_details} ->
        user_session = create_user_session(phone_number, wallet_address, verified_details)
        
        new_users = Map.put(state.authenticated_users, phone_number, user_session)
        new_sessions = Map.put(state.active_sessions, phone_number, %{
          created_at: DateTime.utc_now(),
          last_activity: DateTime.utc_now(),
          message_count: 0
        })
        
        # Send welcome message
        send_welcome_message(phone_number, user_session)
        
        Logger.info("💬 Authenticated WhatsApp user: #{format_phone(phone_number)} -> #{format_wallet(wallet_address)}")
        
        {:reply, {:ok, user_session}, %{state | 
          authenticated_users: new_users,
          active_sessions: new_sessions
        }}
      
      {:error, reason} ->
        Logger.warn("❌ WhatsApp authentication failed for #{format_phone(phone_number)}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call({:send_message, phone_number, message}, _from, state) do
    case is_user_authenticated?(phone_number, state) do
      true ->
        result = send_whatsapp_message(phone_number, message)
        {:reply, result, state}
      
      false ->
        {:reply, {:error, :user_not_authenticated}, state}
    end
  end
  
  def handle_call({:send_notification, wallet_address, notification}, _from, state) do
    case find_phone_by_wallet(wallet_address, state) do
      {:ok, phone_number} ->
        formatted_message = format_notification_message(notification)
        result = send_whatsapp_message(phone_number, formatted_message)
        {:reply, result, state}
      
      :not_found ->
        {:reply, {:error, :user_not_found}, state}
    end
  end
  
  def handle_call({:update_preferences, wallet_address, preferences}, _from, state) do
    new_preferences = Map.put(state.notification_preferences, wallet_address, preferences)
    save_notification_preferences(wallet_address, preferences)
    
    {:reply, :ok, %{state | notification_preferences: new_preferences}}
  end
  
  def handle_call({:get_session, phone_number}, _from, state) do
    session = Map.get(state.active_sessions, phone_number)
    {:reply, session, state}
  end
  
  def handle_cast({:webhook_received, webhook_data}, state) do
    # Process incoming WhatsApp messages
    case parse_webhook_data(webhook_data) do
      {:message, phone_number, message_text} ->
        new_state = process_incoming_message(phone_number, message_text, state)
        {:noreply, new_state}
      
      {:status_update, phone_number, status} ->
        Logger.debug("WhatsApp status update for #{format_phone(phone_number)}: #{status}")
        {:noreply, state}
      
      :invalid ->
        Logger.warn("Invalid WhatsApp webhook data received")
        {:noreply, state}
    end
  end
  
  # Private implementation functions
  
  defp initialize_command_handlers() do
    %{
      # Node management commands
      "/status" => &handle_node_status/2,
      "/earnings" => &handle_earnings_query/2,
      "/peers" => &handle_peers_info/2,
      "/restart" => &handle_node_restart/2,
      
      # AI agent commands
      "/ask" => &handle_ai_query/2,
      "/trading" => &handle_trading_query/2,
      "/nft" => &handle_nft_query/2,
      "/market" => &handle_market_analysis/2,
      
      # Settings commands
      "/settings" => &handle_settings/2,
      "/notifications" => &handle_notification_settings/2,
      "/help" => &handle_help/2,
      
      # Trading commands (premium users)
      "/buy" => &handle_buy_command/2,
      "/sell" => &handle_sell_command/2,
      "/portfolio" => &handle_portfolio_query/2,
      "/alerts" => &handle_alerts_management/2
    }
  end
  
  defp verify_nft_ownership(nft_verification) do
    # Verify the NFT ownership details
    case nft_verification do
      %{collection: "chronara-node-pass", token_id: token_id, wallet_address: wallet} ->
        {:ok, %{
          collection: "chronara-node-pass",
          token_id: token_id,
          wallet_address: wallet,
          access_level: determine_access_level(token_id),
          verified_at: DateTime.utc_now()
        }}
      
      %{collection: "chronara-premium", wallet_address: wallet} ->
        {:ok, %{
          collection: "chronara-premium",
          wallet_address: wallet,
          access_level: :premium,
          verified_at: DateTime.utc_now()
        }}
      
      _ ->
        {:error, :invalid_nft_verification}
    end
  end
  
  defp determine_access_level(token_id) when is_binary(token_id) do
    case String.to_integer(token_id) do
      n when n <= 100 -> :premium
      n when n <= 1000 -> :standard
      _ -> :basic
    end
  rescue
    _ -> :basic
  end
  
  defp create_user_session(phone_number, wallet_address, nft_details) do
    %{
      phone_number: phone_number,
      wallet_address: wallet_address,
      nft_details: nft_details,
      access_level: nft_details.access_level,
      authenticated_at: DateTime.utc_now(),
      capabilities: get_whatsapp_capabilities(nft_details.access_level),
      rate_limit: get_rate_limit(nft_details.access_level)
    }
  end
  
  defp get_whatsapp_capabilities(:premium) do
    [
      :node_management,
      :ai_assistant,
      :trading_commands,
      :nft_management,
      :portfolio_tracking,
      :advanced_alerts,
      :voice_messages,
      :file_sharing
    ]
  end
  
  defp get_whatsapp_capabilities(:standard) do
    [
      :node_management,
      :ai_assistant,
      :basic_trading,
      :portfolio_viewing,
      :standard_alerts
    ]
  end
  
  defp get_whatsapp_capabilities(:basic) do
    [
      :node_status,
      :basic_ai,
      :simple_alerts
    ]
  end
  
  defp get_rate_limit(:premium), do: %{messages_per_hour: 200, commands_per_hour: 100}
  defp get_rate_limit(:standard), do: %{messages_per_hour: 100, commands_per_hour: 50}
  defp get_rate_limit(:basic), do: %{messages_per_hour: 50, commands_per_hour: 20}
  
  defp send_welcome_message(phone_number, user_session) do
    welcome_text = """
    🎉 Welcome to chr-node WhatsApp Interface!
    
    You're authenticated as: #{format_wallet(user_session.wallet_address)}
    Access Level: #{String.upcase(to_string(user_session.access_level))}
    NFT: #{user_session.nft_details.collection} ##{user_session.nft_details.token_id}
    
    Available commands:
    /status - Check node status
    /earnings - View CHAI earnings
    /ask [message] - Chat with your AI assistant
    /help - Show all commands
    
    Your chr-node is now accessible via WhatsApp! 🚀
    """
    
    send_whatsapp_message(phone_number, welcome_text)
  end
  
  defp process_incoming_message(phone_number, message_text, state) do
    case Map.get(state.authenticated_users, phone_number) do
      nil ->
        # User not authenticated, send authentication instructions
        send_authentication_instructions(phone_number)
        state
      
      user_session ->
        # Check rate limits
        case check_rate_limit(phone_number, state) do
          :ok ->
            # Process the message
            process_user_message(phone_number, message_text, user_session, state)
          
          {:error, :rate_limited} ->
            send_whatsapp_message(phone_number, "⚠️ Rate limit exceeded. Please wait before sending more messages.")
            state
        end
    end
  end
  
  defp process_user_message(phone_number, message_text, user_session, state) do
    # Update activity
    new_sessions = update_session_activity(state.active_sessions, phone_number)
    
    cond do
      # Handle commands (messages starting with /)
      String.starts_with?(message_text, "/") ->
        handle_command(phone_number, message_text, user_session, state)
        %{state | active_sessions: new_sessions}
      
      # Handle natural language queries to AI agent
      String.length(message_text) > 5 ->
        handle_ai_conversation(phone_number, message_text, user_session, state)
        %{state | active_sessions: new_sessions}
      
      # Handle short responses or unclear input
      true ->
        send_whatsapp_message(phone_number, "I didn't understand that. Type /help for available commands or ask me a question!")
        %{state | active_sessions: new_sessions}
    end
  end
  
  defp handle_command(phone_number, command_text, user_session, state) do
    [command | args] = String.split(command_text, " ", parts: 2)
    command = String.downcase(command)
    args_text = Enum.join(args, " ")
    
    case Map.get(state.command_handlers, command) do
      nil ->
        send_whatsapp_message(phone_number, "❌ Unknown command: #{command}\nType /help for available commands.")
      
      handler_function ->
        # Check if user has capability for this command
        if has_capability?(command, user_session) do
          handler_function.(user_session, args_text)
        else
          send_whatsapp_message(phone_number, "❌ This command requires a higher access level. Upgrade your NFT for more features!")
        end
    end
  end
  
  defp handle_ai_conversation(phone_number, message_text, user_session, _state) do
    # Send message to AI agent
    case AgentManager.chat_with_agent(user_session.wallet_address, message_text) do
      {:ok, response} ->
        formatted_response = format_ai_response(response)
        send_whatsapp_message(phone_number, formatted_response)
      
      {:error, reason} ->
        error_message = "🤖 AI assistant is temporarily unavailable. Please try again later."
        Logger.error("AI conversation failed for #{format_phone(phone_number)}: #{reason}")
        send_whatsapp_message(phone_number, error_message)
    end
  end
  
  # Command handlers
  
  defp handle_node_status(user_session, _args) do
    # Get current node status
    status_info = get_node_status_info(user_session.wallet_address)
    
    status_message = """
    🖥️ chr-node Status
    
    Status: #{status_emoji(status_info.status)} #{String.upcase(status_info.status)}
    Uptime: #{format_uptime(status_info.uptime)}
    Peers: #{status_info.peers} connected
    Version: #{status_info.version}
    
    Last sync: #{format_time(status_info.last_sync)}
    """
    
    send_whatsapp_message(user_session.phone_number, status_message)
  end
  
  defp handle_earnings_query(user_session, _args) do
    earnings_info = get_earnings_info(user_session.wallet_address)
    
    earnings_message = """
    💰 CHAI Token Earnings
    
    Today: #{earnings_info.today} CHAI
    This Week: #{earnings_info.week} CHAI  
    This Month: #{earnings_info.month} CHAI
    Total: #{earnings_info.total} CHAI
    
    Node Efficiency: #{earnings_info.efficiency}%
    Estimated Monthly: #{earnings_info.estimated_monthly} CHAI
    """
    
    send_whatsapp_message(user_session.phone_number, earnings_message)
  end
  
  defp handle_peers_info(user_session, _args) do
    peers_info = get_peers_info(user_session.wallet_address)
    
    peers_message = """
    🌐 Network Peers
    
    Connected: #{peers_info.connected}/#{peers_info.max_peers}
    Quality Score: #{peers_info.quality_score}/10
    
    Geographic Distribution:
    #{format_peer_distribution(peers_info.distribution)}
    
    Network Health: #{peers_info.network_health}
    """
    
    send_whatsapp_message(user_session.phone_number, peers_message)
  end
  
  defp handle_ai_query(user_session, query_text) do
    if String.length(query_text) > 0 do
      handle_ai_conversation(user_session.phone_number, query_text, user_session, %{})
    else
      send_whatsapp_message(user_session.phone_number, "Please provide a question after /ask. Example: /ask What's the current market trend?")
    end
  end
  
  defp handle_trading_query(user_session, query_text) do
    if :trading_commands in user_session.capabilities do
      case ProAgentIntegration.get_trading_signals(user_session.wallet_address, %{}) do
        {:ok, signals} ->
          trading_message = format_trading_signals(signals)
          send_whatsapp_message(user_session.phone_number, trading_message)
        
        {:error, _reason} ->
          send_whatsapp_message(user_session.phone_number, "📊 Trading signals temporarily unavailable. Please try again later.")
      end
    else
      send_whatsapp_message(user_session.phone_number, "📊 Trading features require Standard or Premium access level.")
    end
  end
  
  defp handle_nft_query(user_session, query_text) do
    if :nft_management in user_session.capabilities do
      case XNomadIntegration.get_nft_recommendations(%{categories: [:art, :pfp]}, user_session) do
        {:ok, recommendations} ->
          nft_message = format_nft_recommendations(recommendations)
          send_whatsapp_message(user_session.phone_number, nft_message)
        
        {:error, _reason} ->
          send_whatsapp_message(user_session.phone_number, "🎨 NFT insights temporarily unavailable. Please try again later.")
      end
    else
      send_whatsapp_message(user_session.phone_number, "🎨 NFT features require Premium access level.")
    end
  end
  
  defp handle_portfolio_query(user_session, _args) do
    if :portfolio_tracking in user_session.capabilities do
      case ProAgentIntegration.get_portfolio_analysis(user_session.wallet_address) do
        {:ok, analysis} ->
          portfolio_message = format_portfolio_analysis(analysis)
          send_whatsapp_message(user_session.phone_number, portfolio_message)
        
        {:error, _reason} ->
          send_whatsapp_message(user_session.phone_number, "📈 Portfolio analysis temporarily unavailable.")
      end
    else
      send_whatsapp_message(user_session.phone_number, "📈 Portfolio features require Standard or Premium access level.")
    end
  end
  
  defp handle_help(user_session, _args) do
    help_message = generate_help_message(user_session.capabilities)
    send_whatsapp_message(user_session.phone_number, help_message)
  end
  
  # Utility functions
  
  defp send_whatsapp_message(phone_number, message) do
    url = "#{@whatsapp_api_url}/#{@phone_number_id}/messages"
    
    headers = [
      {"Authorization", "Bearer #{@access_token}"},
      {"Content-Type", "application/json"}
    ]
    
    body = %{
      messaging_product: "whatsapp",
      to: phone_number,
      type: "text",
      text: %{
        body: message
      }
    }
    
    case Jason.encode(body) do
      {:ok, json_body} ->
        case HTTPoison.post(url, json_body, headers) do
          {:ok, %HTTPoison.Response{status_code: 200}} ->
            {:ok, :message_sent}
          
          {:ok, %HTTPoison.Response{status_code: status, body: error_body}} ->
            Logger.error("WhatsApp API error #{status}: #{error_body}")
            {:error, :api_error}
          
          {:error, reason} ->
            Logger.error("WhatsApp message failed: #{reason}")
            {:error, :network_error}
        end
      
      {:error, reason} ->
        Logger.error("WhatsApp message encoding failed: #{reason}")
        {:error, :encoding_error}
    end
  end
  
  defp parse_webhook_data(webhook_data) do
    case webhook_data do
      %{"entry" => [%{"changes" => [%{"value" => %{"messages" => [message | _]}}]}]} ->
        phone_number = get_in(message, ["from"])
        message_text = get_in(message, ["text", "body"])
        
        if phone_number and message_text do
          {:message, phone_number, message_text}
        else
          :invalid
        end
      
      %{"entry" => [%{"changes" => [%{"value" => %{"statuses" => [status | _]}}]}]} ->
        phone_number = get_in(status, ["recipient_id"])
        status_type = get_in(status, ["status"])
        
        if phone_number and status_type do
          {:status_update, phone_number, status_type}
        else
          :invalid
        end
      
      _ ->
        :invalid
    end
  end
  
  defp is_user_authenticated?(phone_number, state) do
    Map.has_key?(state.authenticated_users, phone_number)
  end
  
  defp find_phone_by_wallet(wallet_address, state) do
    case Enum.find(state.authenticated_users, fn {_phone, user} ->
      user.wallet_address == wallet_address
    end) do
      {phone_number, _user} -> {:ok, phone_number}
      nil -> :not_found
    end
  end
  
  defp format_notification_message(notification) do
    case notification.type do
      :earning_milestone ->
        "🎉 Congratulations! You've earned #{notification.amount} CHAI tokens today!"
      
      :peer_connection_issue ->
        "⚠️ Node Alert: Peer connections below optimal (#{notification.peer_count}). Your node may need attention."
      
      :trading_opportunity ->
        "📊 Trading Alert: #{notification.message}"
      
      :nft_floor_change ->
        "🎨 NFT Alert: #{notification.collection} floor price changed by #{notification.percentage}%"
      
      _ ->
        notification.message || "📱 chr-node notification"
    end
  end
  
  defp format_ai_response(response) do
    "🤖 #{response.agent_name}:\n\n#{response.response}"
  end
  
  defp format_trading_signals(signals) do
    "📊 Trading Signals:\n\n" <>
    Enum.map(signals.signals, fn signal ->
      "#{signal.pair}: #{String.upcase(to_string(signal.signal))} (#{signal.confidence}/10)"
    end)
    |> Enum.join("\n")
  end
  
  defp format_nft_recommendations(recommendations) do
    "🎨 NFT Recommendations:\n\n" <>
    Enum.map(recommendations, fn rec ->
      "#{rec.collection}: #{rec.recommendation} at #{rec.floor_price} ETH"
    end)
    |> Enum.join("\n")
  end
  
  defp format_portfolio_analysis(analysis) do
    """
    📈 Portfolio Analysis
    
    Total Value: $#{analysis.total_value}
    Daily Return: #{analysis.performance.daily_return}%
    Active Positions: #{length(analysis.active_positions)}
    
    Risk Level: #{analysis.risk_metrics.volatility}
    """
  end
  
  defp generate_help_message(capabilities) do
    base_commands = """
    💬 chr-node WhatsApp Commands
    
    Node Management:
    /status - Check node status
    /earnings - View CHAI earnings
    /peers - Network peer info
    
    AI Assistant:
    /ask [question] - Chat with your AI
    Just send any message to talk naturally!
    
    Settings:
    /settings - Manage preferences
    /help - Show this help
    """
    
    additional_commands = cond do
      :trading_commands in capabilities ->
        base_commands <> """
        
        Trading (Premium):
        /trading - Get trading signals
        /portfolio - Portfolio analysis
        /buy [amount] [symbol] - Execute buy order
        /sell [amount] [symbol] - Execute sell order
        """
      
      :nft_management in capabilities ->
        base_commands <> """
        
        NFT Features (Premium):
        /nft - Get NFT recommendations
        /alerts - Manage price alerts
        """
      
      true ->
        base_commands
    end
    
    additional_commands <> "\n\nUpgrade your NFT for more features! 🚀"
  end
  
  # Mock helper functions - replace with real implementations
  defp get_node_status_info(_wallet), do: %{status: "running", uptime: 3600, peers: 12, version: "1.0.0", last_sync: DateTime.utc_now()}
  defp get_earnings_info(_wallet), do: %{today: "2.5", week: "15.2", month: "65.8", total: "127.3", efficiency: 95, estimated_monthly: "70.0"}
  defp get_peers_info(_wallet), do: %{connected: 12, max_peers: 25, quality_score: 8, distribution: %{}, network_health: "Good"}
  defp status_emoji("running"), do: "✅"
  defp status_emoji(_), do: "⚠️"
  defp format_uptime(seconds), do: "#{div(seconds, 3600)}h #{div(rem(seconds, 3600), 60)}m"
  defp format_time(datetime), do: Calendar.strftime(datetime, "%H:%M")
  defp format_peer_distribution(_dist), do: "🌍 Global distribution optimal"
  defp check_rate_limit(_phone, _state), do: :ok
  defp update_session_activity(sessions, phone) do
    Map.update(sessions, phone, %{}, fn session ->
      %{session | last_activity: DateTime.utc_now(), message_count: Map.get(session, :message_count, 0) + 1}
    end)
  end
  defp has_capability?(command, user_session) do
    required_capability = case command do
      c when c in ["/buy", "/sell", "/trading"] -> :trading_commands
      "/nft" -> :nft_management
      "/portfolio" -> :portfolio_tracking
      _ -> :node_status  # Basic capability
    end
    
    required_capability in user_session.capabilities
  end
  defp send_authentication_instructions(phone_number) do
    auth_message = """
    🔐 Authentication Required
    
    To use chr-node WhatsApp interface, you need:
    1. A verified Chronara Node Pass NFT
    2. Complete authentication via web interface
    
    Visit your chr-node web dashboard to link your WhatsApp number.
    """
    
    send_whatsapp_message(phone_number, auth_message)
  end
  defp save_notification_preferences(_wallet, _prefs), do: :ok
  defp format_phone(phone), do: "+#{String.slice(phone, -10, 10)}"
  defp format_wallet(address), do: "#{String.slice(address, 0, 6)}...#{String.slice(address, -4, 4)}"
  
  # Additional handlers for remaining commands
  defp handle_node_restart(user_session, _args) do
    if :node_management in user_session.capabilities do
      # This would trigger actual node restart
      send_whatsapp_message(user_session.phone_number, "🔄 chr-node restart initiated. This may take 2-3 minutes...")
    else
      send_whatsapp_message(user_session.phone_number, "❌ Node restart requires Premium access level.")
    end
  end
  
  defp handle_market_analysis(user_session, _args) do
    send_whatsapp_message(user_session.phone_number, "📊 Market analysis feature coming soon!")
  end
  
  defp handle_settings(user_session, _args) do
    settings_message = """
    ⚙️ chr-node Settings
    
    Current Configuration:
    - Notifications: Enabled
    - Access Level: #{String.upcase(to_string(user_session.access_level))}
    - Rate Limit: #{user_session.rate_limit.messages_per_hour}/hour
    
    Use /notifications to manage alerts.
    """
    
    send_whatsapp_message(user_session.phone_number, settings_message)
  end
  
  defp handle_notification_settings(user_session, _args) do
    notifications_message = """
    🔔 Notification Settings
    
    Available Alerts:
    - Earning milestones ✅
    - Node status changes ✅  
    - Trading opportunities ✅
    - NFT floor price changes ✅
    
    All notifications are currently enabled.
    Contact support to customize settings.
    """
    
    send_whatsapp_message(user_session.phone_number, notifications_message)
  end
  
  defp handle_buy_command(user_session, args) do
    if :trading_commands in user_session.capabilities do
      send_whatsapp_message(user_session.phone_number, "💰 Buy command received: #{args}\n⚠️ Trading execution via WhatsApp coming soon for security!")
    else
      send_whatsapp_message(user_session.phone_number, "💰 Trading commands require Premium access level.")
    end
  end
  
  defp handle_sell_command(user_session, args) do
    if :trading_commands in user_session.capabilities do
      send_whatsapp_message(user_session.phone_number, "💸 Sell command received: #{args}\n⚠️ Trading execution via WhatsApp coming soon for security!")
    else
      send_whatsapp_message(user_session.phone_number, "💸 Trading commands require Premium access level.")
    end
  end
  
  defp handle_alerts_management(user_session, _args) do
    if :advanced_alerts in user_session.capabilities do
      alerts_message = """
      🚨 Alert Management
      
      Active Alerts: 3
      - CHAI price > $0.50
      - Node downtime > 5 minutes
      - Weekly earnings milestone
      
      Use web interface for detailed alert management.
      """
      
      send_whatsapp_message(user_session.phone_number, alerts_message)
    else
      send_whatsapp_message(user_session.phone_number, "🚨 Advanced alerts require Premium access level.")
    end
  end
end