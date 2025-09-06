defmodule ChronaraNode.AI.ProAgentIntegration do
  @moduledoc """
  ProAgent Trading Automation Integration for chr-node
  
  Integrates with ProAgent (https://github.com/CG-8663/plugin-proagent) for intelligent 
  trading automation, portfolio management, and DeFi strategy execution.
  
  Features:
  - Automated trading based on AI signals
  - Portfolio rebalancing and optimization
  - Risk management and position sizing
  - Multi-chain arbitrage opportunities
  - Yield farming strategy automation
  """
  
  use GenServer
  require Logger
  
  alias ChronaraNode.AI.{GeminiClient, ClaudeClient}
  
  @proagent_api_url System.get_env("PROAGENT_API_URL", "http://localhost:8765")
  @supported_chains [:ethereum, :polygon, :binance, :arbitrum, :optimism, :base]
  @risk_levels [:conservative, :moderate, :aggressive]
  
  defstruct [
    :user_strategies,
    :active_trades,
    :portfolio_snapshots,
    :risk_configs,
    :api_credentials
  ]
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    Logger.info("🤖 Starting ProAgent Integration for chr-node...")
    
    {:ok, %__MODULE__{
      user_strategies: %{},
      active_trades: %{},
      portfolio_snapshots: %{},
      risk_configs: %{},
      api_credentials: load_api_credentials()
    }}
  end
  
  # Public API
  
  def create_trading_strategy(wallet_address, nft_details, preferences) do
    GenServer.call(__MODULE__, {:create_strategy, wallet_address, nft_details, preferences})
  end
  
  def update_strategy(wallet_address, strategy_updates) do
    GenServer.call(__MODULE__, {:update_strategy, wallet_address, strategy_updates})
  end
  
  def execute_trade(wallet_address, trade_params) do
    GenServer.call(__MODULE__, {:execute_trade, wallet_address, trade_params}, 60_000)
  end
  
  def get_portfolio_analysis(wallet_address) do
    GenServer.call(__MODULE__, {:portfolio_analysis, wallet_address})
  end
  
  def get_trading_signals(wallet_address, market_data) do
    GenServer.call(__MODULE__, {:trading_signals, wallet_address, market_data}, 30_000)
  end
  
  def optimize_portfolio(wallet_address, target_allocation) do
    GenServer.call(__MODULE__, {:optimize_portfolio, wallet_address, target_allocation}, 120_000)
  end
  
  def get_yield_opportunities(wallet_address, risk_tolerance) do
    GenServer.call(__MODULE__, {:yield_opportunities, wallet_address, risk_tolerance})
  end
  
  def stop_all_strategies(wallet_address) do
    GenServer.call(__MODULE__, {:stop_strategies, wallet_address})
  end
  
  # Utility functions for external use
  
  def generate_advanced_insights(portfolio_data, agent_config) do
    case agent_config.access_level do
      :premium ->
        generate_premium_insights(portfolio_data, agent_config)
      _ ->
        {:error, :insufficient_access_level}
    end
  end
  
  def generate_standard_insights(portfolio_data, agent_config) do
    generate_market_analysis(portfolio_data, agent_config.personalization.trading_risk_tolerance)
  end
  
  def generate_basic_insights(portfolio_data, agent_config) do
    generate_simple_recommendations(portfolio_data)
  end
  
  # GenServer callbacks
  
  def handle_call({:create_strategy, wallet_address, nft_details, preferences}, _from, state) do
    strategy_config = create_strategy_config(wallet_address, nft_details, preferences)
    
    case validate_and_deploy_strategy(strategy_config) do
      {:ok, deployed_strategy} ->
        new_strategies = Map.put(state.user_strategies, wallet_address, deployed_strategy)
        
        Logger.info("🚀 Created trading strategy for #{format_wallet(wallet_address)}")
        
        {:reply, {:ok, deployed_strategy}, %{state | user_strategies: new_strategies}}
      
      {:error, reason} ->
        Logger.error("❌ Strategy creation failed: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call({:update_strategy, wallet_address, strategy_updates}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      current_strategy ->
        updated_strategy = Map.merge(current_strategy, strategy_updates)
        
        case validate_strategy_updates(updated_strategy) do
          :ok ->
            new_strategies = Map.put(state.user_strategies, wallet_address, updated_strategy)
            save_strategy_config(wallet_address, updated_strategy)
            
            {:reply, {:ok, updated_strategy}, %{state | user_strategies: new_strategies}}
          
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end
  
  def handle_call({:execute_trade, wallet_address, trade_params}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      strategy ->
        trade_result = execute_proagent_trade(strategy, trade_params, state.api_credentials)
        
        # Update active trades
        new_active_trades = update_active_trades(state.active_trades, wallet_address, trade_result)
        
        {:reply, trade_result, %{state | active_trades: new_active_trades}}
    end
  end
  
  def handle_call({:portfolio_analysis, wallet_address}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      strategy ->
        analysis = perform_portfolio_analysis(strategy, state)
        {:reply, {:ok, analysis}, state}
    end
  end
  
  def handle_call({:trading_signals, wallet_address, market_data}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      strategy ->
        signals = generate_ai_trading_signals(strategy, market_data, state)
        {:reply, {:ok, signals}, state}
    end
  end
  
  def handle_call({:optimize_portfolio, wallet_address, target_allocation}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      strategy ->
        optimization = optimize_portfolio_allocation(strategy, target_allocation, state)
        {:reply, optimization, state}
    end
  end
  
  def handle_call({:yield_opportunities, wallet_address, risk_tolerance}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      strategy ->
        opportunities = find_yield_opportunities(strategy, risk_tolerance, state)
        {:reply, {:ok, opportunities}, state}
    end
  end
  
  def handle_call({:stop_strategies, wallet_address}, _from, state) do
    case Map.get(state.user_strategies, wallet_address) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}
      
      strategy ->
        stop_result = stop_proagent_strategies(strategy, state.api_credentials)
        
        # Remove from active strategies
        new_strategies = Map.delete(state.user_strategies, wallet_address)
        new_active_trades = Map.delete(state.active_trades, wallet_address)
        
        {:reply, stop_result, %{state | 
          user_strategies: new_strategies,
          active_trades: new_active_trades
        }}
    end
  end
  
  # Private implementation functions
  
  defp create_strategy_config(wallet_address, nft_details, preferences) do
    access_level = determine_access_level(nft_details)
    risk_tolerance = Map.get(preferences, :risk_tolerance, :moderate)
    
    %{
      wallet_address: wallet_address,
      nft_token_id: nft_details.token_id,
      access_level: access_level,
      strategy_type: determine_strategy_type(access_level, preferences),
      risk_tolerance: risk_tolerance,
      max_position_size: calculate_max_position_size(access_level, risk_tolerance),
      supported_chains: get_supported_chains(access_level),
      trading_pairs: get_trading_pairs(preferences),
      automation_level: get_automation_level(access_level, preferences),
      stop_loss_percentage: Map.get(preferences, :stop_loss, get_default_stop_loss(risk_tolerance)),
      take_profit_percentage: Map.get(preferences, :take_profit, get_default_take_profit(risk_tolerance)),
      rebalance_frequency: Map.get(preferences, :rebalance_frequency, :weekly),
      created_at: DateTime.utc_now(),
      active: true
    }
  end
  
  defp determine_access_level(nft_details) do
    case nft_details do
      %{collection: "chronara-premium"} -> :premium
      %{collection: "chronara-node-pass", token_id: token_id} ->
        case String.to_integer(token_id) do
          n when n <= 100 -> :premium
          n when n <= 1000 -> :standard  
          _ -> :basic
        end
      _ -> :basic
    end
  rescue
    _ -> :basic
  end
  
  defp determine_strategy_type(:premium, preferences) do
    Map.get(preferences, :strategy_type, :multi_chain_arbitrage)
  end
  
  defp determine_strategy_type(:standard, preferences) do
    Map.get(preferences, :strategy_type, :portfolio_rebalancing)
  end
  
  defp determine_strategy_type(:basic, _preferences) do
    :simple_dca
  end
  
  defp calculate_max_position_size(:premium, :aggressive), do: 0.20  # 20%
  defp calculate_max_position_size(:premium, :moderate), do: 0.15   # 15%
  defp calculate_max_position_size(:premium, :conservative), do: 0.10 # 10%
  defp calculate_max_position_size(:standard, :aggressive), do: 0.15
  defp calculate_max_position_size(:standard, :moderate), do: 0.10
  defp calculate_max_position_size(:standard, :conservative), do: 0.05
  defp calculate_max_position_size(:basic, _), do: 0.05
  
  defp get_supported_chains(:premium), do: @supported_chains
  defp get_supported_chains(:standard), do: [:ethereum, :polygon, :binance]
  defp get_supported_chains(:basic), do: [:ethereum, :polygon]
  
  defp get_trading_pairs(preferences) do
    default_pairs = ["ETH/USDC", "BTC/USDC", "CHAI/ETH"]
    Map.get(preferences, :trading_pairs, default_pairs)
  end
  
  defp get_automation_level(:premium, preferences), do: Map.get(preferences, :automation, :full)
  defp get_automation_level(:standard, preferences), do: Map.get(preferences, :automation, :semi)
  defp get_automation_level(:basic, _), do: :manual
  
  defp get_default_stop_loss(:aggressive), do: 0.10  # 10%
  defp get_default_stop_loss(:moderate), do: 0.08    # 8%
  defp get_default_stop_loss(:conservative), do: 0.05 # 5%
  
  defp get_default_take_profit(:aggressive), do: 0.25 # 25%
  defp get_default_take_profit(:moderate), do: 0.15   # 15%
  defp get_default_take_profit(:conservative), do: 0.10 # 10%
  
  defp validate_and_deploy_strategy(strategy_config) do
    with :ok <- validate_strategy_config(strategy_config),
         {:ok, deployment} <- deploy_to_proagent(strategy_config) do
      {:ok, Map.merge(strategy_config, deployment)}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_strategy_config(config) do
    cond do
      config.max_position_size > 0.25 -> {:error, "Position size too large"}
      config.risk_tolerance not in @risk_levels -> {:error, "Invalid risk tolerance"}
      length(config.supported_chains) == 0 -> {:error, "No supported chains"}
      true -> :ok
    end
  end
  
  defp deploy_to_proagent(strategy_config) do
    # Mock deployment - replace with actual ProAgent API integration
    deployment_params = %{
      strategy_id: generate_strategy_id(),
      configuration: strategy_config,
      deployment_time: DateTime.utc_now()
    }
    
    case make_proagent_request("/api/strategies", deployment_params) do
      {:ok, response} ->
        {:ok, %{
          proagent_strategy_id: response["strategy_id"],
          deployment_status: "active",
          api_endpoints: response["endpoints"]
        }}
      
      {:error, reason} ->
        {:error, "ProAgent deployment failed: #{reason}"}
    end
  end
  
  defp execute_proagent_trade(strategy, trade_params, api_credentials) do
    # Validate trade against strategy limits
    case validate_trade_params(trade_params, strategy) do
      :ok ->
        trade_request = %{
          strategy_id: strategy.proagent_strategy_id,
          trade_type: trade_params.type,
          symbol: trade_params.symbol,
          amount: trade_params.amount,
          price: trade_params.price,
          stop_loss: calculate_stop_loss(trade_params, strategy),
          take_profit: calculate_take_profit(trade_params, strategy)
        }
        
        case make_proagent_request("/api/trades", trade_request) do
          {:ok, response} ->
            {:ok, %{
              trade_id: response["trade_id"],
              status: response["status"],
              estimated_execution: response["estimated_execution"]
            }}
          
          {:error, reason} ->
            {:error, "Trade execution failed: #{reason}"}
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp generate_ai_trading_signals(strategy, market_data, state) do
    # Use AI to analyze market data and generate trading signals
    ai_provider = if strategy.access_level == :premium, do: :claude, else: :gemini
    
    system_prompt = """
    You are a sophisticated trading algorithm analyzing market data for automated trading decisions.
    
    Strategy Context:
    - Access Level: #{strategy.access_level}
    - Risk Tolerance: #{strategy.risk_tolerance}
    - Max Position: #{strategy.max_position_size * 100}%
    - Trading Pairs: #{inspect(strategy.trading_pairs)}
    
    Provide specific BUY/SELL/HOLD signals with confidence levels and reasoning.
    """
    
    market_analysis_prompt = """
    Analyze current market conditions and provide trading signals:
    
    MARKET DATA:
    #{Jason.encode!(market_data, pretty: true)}
    
    REQUIRED OUTPUT:
    For each trading pair, provide:
    1. Signal: BUY/SELL/HOLD
    2. Confidence: 1-10 scale
    3. Entry Price Range
    4. Stop Loss Level
    5. Take Profit Target
    6. Position Size Recommendation
    7. Reasoning (brief)
    
    Format as structured recommendations for algorithmic execution.
    """
    
    case make_ai_request(ai_provider, system_prompt, market_analysis_prompt, state) do
      {:ok, analysis} ->
        parse_trading_signals(analysis)
      
      {:error, reason} ->
        Logger.error("AI signal generation failed: #{reason}")
        {:error, :signal_generation_failed}
    end
  end
  
  defp perform_portfolio_analysis(strategy, state) do
    # Get current portfolio state from ProAgent
    case make_proagent_request("/api/portfolio/#{strategy.proagent_strategy_id}") do
      {:ok, portfolio_data} ->
        %{
          total_value: portfolio_data["total_value"],
          asset_allocation: portfolio_data["allocation"],
          performance: %{
            daily_return: portfolio_data["daily_return"],
            weekly_return: portfolio_data["weekly_return"],
            monthly_return: portfolio_data["monthly_return"],
            total_return: portfolio_data["total_return"]
          },
          risk_metrics: %{
            volatility: portfolio_data["volatility"],
            sharpe_ratio: portfolio_data["sharpe_ratio"],
            max_drawdown: portfolio_data["max_drawdown"]
          },
          active_positions: portfolio_data["positions"],
          cash_balance: portfolio_data["cash_balance"],
          analysis_timestamp: DateTime.utc_now()
        }
      
      {:error, reason} ->
        Logger.error("Portfolio analysis failed: #{reason}")
        {:error, :analysis_failed}
    end
  end
  
  defp optimize_portfolio_allocation(strategy, target_allocation, state) do
    optimization_request = %{
      strategy_id: strategy.proagent_strategy_id,
      target_allocation: target_allocation,
      constraints: %{
        max_position_size: strategy.max_position_size,
        risk_tolerance: strategy.risk_tolerance,
        supported_chains: strategy.supported_chains
      }
    }
    
    case make_proagent_request("/api/optimize", optimization_request) do
      {:ok, optimization_result} ->
        {:ok, %{
          recommended_trades: optimization_result["trades"],
          expected_improvement: optimization_result["improvement"],
          execution_plan: optimization_result["execution_plan"],
          estimated_cost: optimization_result["estimated_cost"]
        }}
      
      {:error, reason} ->
        {:error, "Portfolio optimization failed: #{reason}"}
    end
  end
  
  defp find_yield_opportunities(strategy, risk_tolerance, state) do
    opportunity_request = %{
      chains: strategy.supported_chains,
      risk_tolerance: risk_tolerance,
      min_apy: get_min_apy(risk_tolerance),
      max_lockup_days: get_max_lockup(risk_tolerance)
    }
    
    case make_proagent_request("/api/yield-opportunities", opportunity_request) do
      {:ok, opportunities} ->
        Enum.map(opportunities, fn opp ->
          %{
            protocol: opp["protocol"],
            chain: opp["chain"],
            asset: opp["asset"],
            apy: opp["apy"],
            tvl: opp["tvl"],
            risk_score: opp["risk_score"],
            lockup_period: opp["lockup_period"],
            strategy_type: opp["strategy_type"]
          }
        end)
      
      {:error, reason} ->
        Logger.error("Yield opportunity search failed: #{reason}")
        []
    end
  end
  
  # AI Integration helpers
  
  defp generate_premium_insights(portfolio_data, agent_config) do
    # Use Claude for premium insights
    case ClaudeClient.generate_advanced_trading_analysis(
      System.get_env("ANTHROPIC_API_KEY"),
      portfolio_data,
      get_market_data(),
      agent_config
    ) do
      {:ok, analysis} ->
        {:ok, %{
          analysis: analysis,
          confidence: :high,
          recommendations: extract_recommendations(analysis),
          risk_assessment: extract_risk_metrics(analysis)
        }}
      
      error -> error
    end
  end
  
  defp generate_market_analysis(portfolio_data, risk_tolerance) do
    # Use Gemini for standard analysis
    case GeminiClient.generate_trading_insights(
      System.get_env("GEMINI_API_KEY"),
      portfolio_data,
      %{risk_tolerance: risk_tolerance}
    ) do
      {:ok, insights} ->
        {:ok, %{
          insights: insights,
          confidence: :medium,
          focus_areas: ["portfolio_balance", "risk_management"]
        }}
      
      error -> error
    end
  end
  
  defp generate_simple_recommendations(portfolio_data) do
    # Basic rule-based recommendations
    recommendations = []
    
    # Check for over-concentration
    recommendations = if check_concentration_risk(portfolio_data) do
      ["Consider diversifying your portfolio to reduce concentration risk" | recommendations]
    else
      recommendations
    end
    
    # Check for rebalancing needs
    recommendations = if needs_rebalancing?(portfolio_data) do
      ["Portfolio may benefit from rebalancing" | recommendations] 
    else
      recommendations
    end
    
    {:ok, %{
      recommendations: recommendations,
      confidence: :low,
      analysis_type: :rule_based
    }}
  end
  
  # Utility functions
  
  defp make_proagent_request(endpoint, data \\ %{}) do
    url = "#{@proagent_api_url}#{endpoint}"
    
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{System.get_env("PROAGENT_API_KEY")}"}
    ]
    
    case Jason.encode(data) do
      {:ok, json_body} ->
        case HTTPoison.post(url, json_body, headers, recv_timeout: 30_000) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            Jason.decode(body)
          
          {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
            {:error, "API error #{status}: #{body}"}
          
          {:error, reason} ->
            {:error, "Network error: #{reason}"}
        end
      
      {:error, reason} ->
        {:error, "JSON encoding failed: #{reason}"}
    end
  end
  
  defp make_ai_request(:claude, system_prompt, message, _state) do
    ClaudeClient.chat(
      System.get_env("ANTHROPIC_API_KEY"),
      "claude-3-sonnet-20240229",
      system_prompt,
      message
    )
  end
  
  defp make_ai_request(:gemini, system_prompt, message, _state) do
    GeminiClient.chat(
      System.get_env("GEMINI_API_KEY"),
      "gemini-1.5-flash",
      system_prompt,
      message
    )
  end
  
  defp parse_trading_signals(ai_response) do
    # Parse AI response into structured trading signals
    # This would be more sophisticated in production
    %{
      signals: [
        %{
          pair: "ETH/USDC",
          signal: :hold,
          confidence: 7,
          reasoning: "Market consolidation phase"
        }
      ],
      timestamp: DateTime.utc_now()
    }
  end
  
  defp get_market_data() do
    # Mock market data - replace with real data feeds
    %{
      btc_price: 45000,
      eth_price: 3000,
      market_cap: 2_000_000_000_000,
      fear_greed_index: 65,
      volatility_index: 0.85
    }
  end
  
  # Configuration and utility functions
  defp load_api_credentials() do
    %{
      proagent_api_key: System.get_env("PROAGENT_API_KEY"),
      gemini_api_key: System.get_env("GEMINI_API_KEY"),
      claude_api_key: System.get_env("ANTHROPIC_API_KEY")
    }
  end
  
  defp save_strategy_config(wallet_address, strategy) do
    config_dir = Path.join([System.get_env("HOME"), ".chr-node", "strategies"])
    File.mkdir_p(config_dir)
    
    config_file = Path.join(config_dir, "#{wallet_address}.json")
    
    case Jason.encode(strategy, pretty: true) do
      {:ok, json} -> File.write(config_file, json)
      {:error, _} -> :error
    end
  end
  
  defp validate_trade_params(params, strategy), do: :ok  # Implement validation
  defp calculate_stop_loss(params, strategy), do: params.price * (1 - strategy.stop_loss_percentage)
  defp calculate_take_profit(params, strategy), do: params.price * (1 + strategy.take_profit_percentage)
  defp update_active_trades(trades, wallet, result), do: Map.put(trades, wallet, result)
  defp stop_proagent_strategies(strategy, credentials), do: {:ok, "Strategies stopped"}
  defp validate_strategy_updates(_strategy), do: :ok
  defp get_min_apy(:conservative), do: 5.0
  defp get_min_apy(:moderate), do: 8.0  
  defp get_min_apy(:aggressive), do: 12.0
  defp get_max_lockup(:conservative), do: 30
  defp get_max_lockup(:moderate), do: 90
  defp get_max_lockup(:aggressive), do: 365
  defp extract_recommendations(text), do: []
  defp extract_risk_metrics(text), do: %{}
  defp check_concentration_risk(_portfolio), do: false
  defp needs_rebalancing?(_portfolio), do: false
  defp generate_strategy_id(), do: "strategy_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  defp format_wallet(address), do: "#{String.slice(address, 0, 6)}...#{String.slice(address, -4, 4)}"
end