defmodule ChronaraNode.AI.AgentManager do
  @moduledoc """
  AI Agent Manager for chr-node with Gemini/Claude integration
  
  Manages personalized AI agents for authenticated node users with NFT-based access.
  Integrates ProAgent trading automation and xNomad.fun NFT agent capabilities.
  """
  
  use GenServer
  require Logger
  
  alias ChronaraNode.AI.{GeminiClient, ClaudeClient, ProAgentIntegration, XNomadIntegration}
  
  @ai_providers [:gemini, :claude]
  @default_provider :gemini
  
  defstruct [
    :user_agents,
    :active_sessions,
    :nft_verifications,
    :personalization_configs,
    :provider_clients
  ]
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("🤖 Starting AI Agent Manager for chr-node...")
    
    # Initialize provider clients
    provider_clients = initialize_providers()
    
    # Load user configurations
    user_agents = load_user_agent_configs()
    
    {:ok, %__MODULE__{
      user_agents: user_agents,
      active_sessions: %{},
      nft_verifications: %{},
      personalization_configs: %{},
      provider_clients: provider_clients
    }}
  end
  
  # Public API
  
  def create_agent(wallet_address, nft_details, preferences \\ %{}) do
    GenServer.call(__MODULE__, {:create_agent, wallet_address, nft_details, preferences})
  end
  
  def get_agent(wallet_address) do
    GenServer.call(__MODULE__, {:get_agent, wallet_address})
  end
  
  def chat_with_agent(wallet_address, message, context \\ %{}) do
    GenServer.call(__MODULE__, {:chat, wallet_address, message, context}, 30_000)
  end
  
  def update_personalization(wallet_address, personalization_data) do
    GenServer.call(__MODULE__, {:update_personalization, wallet_address, personalization_data})
  end
  
  def get_trading_insights(wallet_address, portfolio_data) do
    GenServer.call(__MODULE__, {:trading_insights, wallet_address, portfolio_data}, 60_000)
  end
  
  def get_nft_recommendations(wallet_address, collection_preferences) do
    GenServer.call(__MODULE__, {:nft_recommendations, wallet_address, collection_preferences}, 30_000)
  end
  
  def list_user_agents() do
    GenServer.call(__MODULE__, :list_agents)
  end
  
  # GenServer callbacks
  
  def handle_call({:create_agent, wallet_address, nft_details, preferences}, _from, state) do
    case verify_nft_access(nft_details) do
      {:ok, access_level} ->
        agent_config = create_agent_config(wallet_address, nft_details, access_level, preferences)
        
        new_user_agents = Map.put(state.user_agents, wallet_address, agent_config)
        new_nft_verifications = Map.put(state.nft_verifications, wallet_address, nft_details)
        
        # Save configuration
        save_agent_config(wallet_address, agent_config)
        
        Logger.info("🤖 Created AI agent for wallet: #{format_wallet(wallet_address)}")
        
        {:reply, {:ok, agent_config}, %{state | 
          user_agents: new_user_agents,
          nft_verifications: new_nft_verifications
        }}
      
      {:error, reason} ->
        Logger.warn("❌ NFT verification failed for #{format_wallet(wallet_address)}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call({:get_agent, wallet_address}, _from, state) do
    agent = Map.get(state.user_agents, wallet_address)
    {:reply, agent, state}
  end
  
  def handle_call({:chat, wallet_address, message, context}, _from, state) do
    case Map.get(state.user_agents, wallet_address) do
      nil ->
        {:reply, {:error, :agent_not_found}, state}
      
      agent_config ->
        response = process_chat_message(agent_config, message, context, state)
        
        # Update session activity
        new_sessions = update_session_activity(state.active_sessions, wallet_address)
        
        {:reply, response, %{state | active_sessions: new_sessions}}
    end
  end
  
  def handle_call({:update_personalization, wallet_address, personalization_data}, _from, state) do
    case Map.get(state.user_agents, wallet_address) do
      nil ->
        {:reply, {:error, :agent_not_found}, state}
      
      agent_config ->
        updated_config = update_agent_personalization(agent_config, personalization_data)
        new_user_agents = Map.put(state.user_agents, wallet_address, updated_config)
        
        save_agent_config(wallet_address, updated_config)
        
        {:reply, {:ok, updated_config}, %{state | user_agents: new_user_agents}}
    end
  end
  
  def handle_call({:trading_insights, wallet_address, portfolio_data}, _from, state) do
    case Map.get(state.user_agents, wallet_address) do
      nil ->
        {:reply, {:error, :agent_not_found}, state}
      
      agent_config ->
        insights = generate_trading_insights(agent_config, portfolio_data, state)
        {:reply, {:ok, insights}, state}
    end
  end
  
  def handle_call({:nft_recommendations, wallet_address, collection_preferences}, _from, state) do
    case Map.get(state.user_agents, wallet_address) do
      nil ->
        {:reply, {:error, :agent_not_found}, state}
      
      agent_config ->
        recommendations = generate_nft_recommendations(agent_config, collection_preferences, state)
        {:reply, {:ok, recommendations}, state}
    end
  end
  
  def handle_call(:list_agents, _from, state) do
    agent_summary = state.user_agents
    |> Enum.map(fn {wallet, config} ->
      %{
        wallet_address: format_wallet(wallet),
        agent_name: config.name,
        access_level: config.access_level,
        created_at: config.created_at,
        last_active: get_last_activity(state.active_sessions, wallet)
      }
    end)
    
    {:reply, agent_summary, state}
  end
  
  # Private functions
  
  defp initialize_providers() do
    Logger.info("🔧 Initializing AI provider clients...")
    
    %{
      gemini: %{
        client: GeminiClient,
        api_key: System.get_env("GEMINI_API_KEY"),
        model: "gemini-1.5-flash",
        available: !is_nil(System.get_env("GEMINI_API_KEY"))
      },
      claude: %{
        client: ClaudeClient,
        api_key: System.get_env("ANTHROPIC_API_KEY"),
        model: "claude-3-sonnet-20240229",
        available: !is_nil(System.get_env("ANTHROPIC_API_KEY"))
      }
    }
  end
  
  defp load_user_agent_configs() do
    config_dir = Path.join([System.get_env("HOME"), ".chr-node", "agents"])
    
    case File.ls(config_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".json"))
        |> Enum.reduce(%{}, fn file, acc ->
          wallet_address = Path.basename(file, ".json")
          config_path = Path.join(config_dir, file)
          
          case File.read(config_path) do
            {:ok, content} ->
              case Jason.decode(content) do
                {:ok, config} -> Map.put(acc, wallet_address, atomize_keys(config))
                _ -> acc
              end
            _ -> acc
          end
        end)
      
      _ -> %{}
    end
  end
  
  defp verify_nft_access(nft_details) do
    # Verify NFT ownership and determine access level
    case nft_details do
      %{collection: "chronara-node-pass", token_id: token_id} ->
        access_level = determine_access_level(token_id)
        {:ok, access_level}
      
      %{collection: "chronara-premium", token_id: _} ->
        {:ok, :premium}
      
      _ ->
        {:error, :invalid_nft}
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
  
  defp determine_access_level(_), do: :basic
  
  defp create_agent_config(wallet_address, nft_details, access_level, preferences) do
    %{
      id: generate_agent_id(),
      wallet_address: wallet_address,
      name: generate_agent_name(preferences),
      access_level: access_level,
      nft_details: nft_details,
      personality: generate_personality(access_level, preferences),
      capabilities: get_capabilities(access_level),
      preferences: preferences,
      personalization: %{
        trading_risk_tolerance: Map.get(preferences, :risk_tolerance, :moderate),
        communication_style: Map.get(preferences, :communication_style, :professional),
        preferred_topics: Map.get(preferences, :interests, []),
        notification_preferences: Map.get(preferences, :notifications, %{})
      },
      integrations: %{
        proagent: access_level in [:standard, :premium],
        xnomad: access_level == :premium,
        whatsapp: true
      },
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end
  
  defp generate_agent_name(preferences) do
    custom_name = Map.get(preferences, :agent_name)
    if custom_name && String.length(custom_name) > 0 do
      custom_name
    else
      "CHAI Assistant"
    end
  end
  
  defp generate_personality(access_level, preferences) do
    base_personality = %{
      tone: Map.get(preferences, :communication_style, :professional),
      expertise_areas: ["blockchain", "trading", "chr-node"],
      response_style: :helpful
    }
    
    case access_level do
      :premium ->
        Map.merge(base_personality, %{
          expertise_areas: base_personality.expertise_areas ++ ["advanced_trading", "nft_analytics", "defi"],
          capabilities: [:real_time_analysis, :predictive_insights, :portfolio_optimization]
        })
      
      :standard ->
        Map.merge(base_personality, %{
          capabilities: [:market_analysis, :trading_suggestions, :portfolio_tracking]
        })
      
      :basic ->
        Map.merge(base_personality, %{
          capabilities: [:basic_info, :chr_node_help, :simple_trading_tips]
        })
    end
  end
  
  defp get_capabilities(:premium) do
    [
      :advanced_trading_analysis,
      :nft_market_insights,
      :portfolio_optimization,
      :real_time_alerts,
      :predictive_analytics,
      :cross_chain_analysis,
      :yield_farming_strategies,
      :risk_assessment
    ]
  end
  
  defp get_capabilities(:standard) do
    [
      :trading_analysis,
      :portfolio_tracking,
      :market_insights,
      :basic_alerts,
      :chr_node_optimization
    ]
  end
  
  defp get_capabilities(:basic) do
    [
      :basic_trading_info,
      :chr_node_help,
      :simple_market_data
    ]
  end
  
  defp process_chat_message(agent_config, message, context, state) do
    provider = determine_provider(agent_config, state.provider_clients)
    
    # Build conversation context
    conversation_context = build_conversation_context(agent_config, context)
    
    # Add chr-node specific context
    chr_node_context = get_chr_node_context(agent_config.wallet_address)
    
    # Prepare system prompt
    system_prompt = build_system_prompt(agent_config, chr_node_context)
    
    case make_ai_request(provider, system_prompt, message, conversation_context, state.provider_clients) do
      {:ok, response} ->
        # Log interaction
        log_interaction(agent_config.wallet_address, message, response)
        
        # Check for action triggers
        actions = detect_action_triggers(response, agent_config)
        
        {:ok, %{
          response: response,
          agent_name: agent_config.name,
          actions: actions,
          timestamp: DateTime.utc_now()
        }}
      
      {:error, reason} ->
        {:error, "AI service unavailable: #{reason}"}
    end
  end
  
  defp determine_provider(agent_config, provider_clients) do
    # Premium users can use Claude, others use Gemini
    preferred_provider = case agent_config.access_level do
      :premium -> :claude
      _ -> :gemini
    end
    
    # Fallback to available provider
    if provider_clients[preferred_provider][:available] do
      preferred_provider
    else
      Enum.find([@default_provider | @ai_providers], fn provider ->
        provider_clients[provider][:available]
      end) || @default_provider
    end
  end
  
  defp build_conversation_context(agent_config, context) do
    %{
      user_wallet: agent_config.wallet_address,
      access_level: agent_config.access_level,
      personality: agent_config.personality,
      personalization: agent_config.personalization,
      previous_messages: Map.get(context, :previous_messages, []),
      current_time: DateTime.utc_now()
    }
  end
  
  defp get_chr_node_context(wallet_address) do
    # Get current node status, earnings, etc.
    %{
      node_status: get_node_status(wallet_address),
      recent_earnings: get_recent_earnings(wallet_address),
      peer_connections: get_peer_connections(wallet_address),
      network_health: get_network_health()
    }
  end
  
  defp build_system_prompt(agent_config, chr_node_context) do
    """
    You are #{agent_config.name}, a personalized AI assistant for a chr-node operator on the Chronara Network.
    
    User Profile:
    - Wallet: #{format_wallet(agent_config.wallet_address)}
    - Access Level: #{agent_config.access_level}
    - NFT: #{agent_config.nft_details.metadata.name} ##{agent_config.nft_details.token_id}
    
    Current Node Status:
    - Status: #{chr_node_context.node_status.status}
    - Peers: #{chr_node_context.peer_connections.count}
    - Recent Earnings: #{chr_node_context.recent_earnings.today} CHAI today
    
    Personality:
    - Communication Style: #{agent_config.personality.tone}
    - Expertise Areas: #{Enum.join(agent_config.personality.expertise_areas, ", ")}
    
    Capabilities Available:
    #{Enum.map(agent_config.capabilities, &"- #{&1}") |> Enum.join("\n")}
    
    Instructions:
    1. Be helpful and knowledgeable about chr-node operations, CHAI token, and blockchain topics
    2. Provide personalized advice based on the user's access level and preferences
    3. Keep responses concise but informative
    4. Suggest actionable steps when appropriate
    5. Reference current node performance when relevant
    
    If asked about trading or NFTs, provide insights appropriate to the user's access level.
    Premium users get advanced analytics, standard users get general advice, basic users get educational content.
    """
  end
  
  defp make_ai_request(provider, system_prompt, message, context, provider_clients) do
    client_config = provider_clients[provider]
    
    case provider do
      :gemini ->
        GeminiClient.chat(
          client_config.api_key,
          client_config.model,
          system_prompt,
          message,
          context
        )
      
      :claude ->
        ClaudeClient.chat(
          client_config.api_key,
          client_config.model,
          system_prompt,
          message,
          context
        )
      
      _ ->
        {:error, :provider_not_available}
    end
  end
  
  defp generate_trading_insights(agent_config, portfolio_data, state) do
    case agent_config.access_level do
      :premium ->
        ProAgentIntegration.generate_advanced_insights(portfolio_data, agent_config)
      
      :standard ->
        ProAgentIntegration.generate_standard_insights(portfolio_data, agent_config)
      
      :basic ->
        ProAgentIntegration.generate_basic_insights(portfolio_data, agent_config)
    end
  end
  
  defp generate_nft_recommendations(agent_config, collection_preferences, state) do
    if agent_config.integrations.xnomad do
      XNomadIntegration.get_nft_recommendations(collection_preferences, agent_config)
    else
      {:error, :feature_not_available}
    end
  end
  
  defp update_agent_personalization(agent_config, personalization_data) do
    updated_personalization = Map.merge(agent_config.personalization, personalization_data)
    
    %{agent_config | 
      personalization: updated_personalization,
      updated_at: DateTime.utc_now()
    }
  end
  
  defp save_agent_config(wallet_address, config) do
    config_dir = Path.join([System.get_env("HOME"), ".chr-node", "agents"])
    File.mkdir_p(config_dir)
    
    config_file = Path.join(config_dir, "#{wallet_address}.json")
    
    case Jason.encode(config, pretty: true) do
      {:ok, json} -> File.write(config_file, json)
      {:error, _} -> :error
    end
  end
  
  defp update_session_activity(sessions, wallet_address) do
    Map.put(sessions, wallet_address, DateTime.utc_now())
  end
  
  defp detect_action_triggers(response, agent_config) do
    actions = []
    
    # Check for trading-related triggers
    actions = if String.contains?(response, ["buy", "sell", "trade"]) and agent_config.integrations.proagent do
      [:suggest_trading_action | actions]
    else
      actions
    end
    
    # Check for NFT-related triggers
    actions = if String.contains?(response, ["nft", "collection"]) and agent_config.integrations.xnomad do
      [:suggest_nft_action | actions]
    else
      actions
    end
    
    # Check for node optimization triggers
    actions = if String.contains?(response, ["optimize", "performance", "peers"]) do
      [:suggest_node_optimization | actions]
    else
      actions
    end
    
    actions
  end
  
  defp log_interaction(wallet_address, message, response) do
    log_entry = %{
      timestamp: DateTime.utc_now(),
      wallet: format_wallet(wallet_address),
      message: String.slice(message, 0, 100),
      response: String.slice(response, 0, 200),
      agent_version: "1.0.0"
    }
    
    Logger.info("🤖 Agent interaction: #{inspect(log_entry)}")
  end
  
  # Mock functions - replace with actual implementations
  defp get_node_status(_wallet_address), do: %{status: "running", uptime: 3600}
  defp get_recent_earnings(_wallet_address), do: %{today: "2.5 CHAI", week: "15.2 CHAI"}
  defp get_peer_connections(_wallet_address), do: %{count: 12, quality: "good"}
  defp get_network_health(), do: %{status: "healthy", total_nodes: 1234}
  defp get_last_activity(sessions, wallet), do: Map.get(sessions, wallet)
  
  # Utility functions
  defp generate_agent_id() do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
  
  defp format_wallet(address) when is_binary(address) do
    "#{String.slice(address, 0, 6)}...#{String.slice(address, -4, 4)}"
  end
  
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
end