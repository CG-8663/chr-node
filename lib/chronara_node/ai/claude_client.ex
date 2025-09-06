defmodule ChronaraNode.AI.ClaudeClient do
  @moduledoc """
  Anthropic Claude API Client for chr-node AI Agent Integration
  
  Premium tier client for advanced AI capabilities with Claude 3.
  Provides superior reasoning for complex trading and NFT analysis.
  """
  
  require Logger
  
  @base_url "https://api.anthropic.com/v1"
  @default_model "claude-3-sonnet-20240229"
  @max_tokens 2048
  @temperature 0.7
  
  @doc """
  Send a chat message to Claude API with system context
  """
  def chat(api_key, model \\ @default_model, system_prompt, message, context \\ %{}) do
    if is_nil(api_key) or String.length(api_key) == 0 do
      {:error, :api_key_not_configured}
    else
      make_chat_request(api_key, model, system_prompt, message, context)
    end
  end
  
  @doc """
  Advanced trading analysis using Claude's superior reasoning
  """
  def generate_advanced_trading_analysis(api_key, portfolio_data, market_data, user_profile) do
    system_prompt = """
    You are a sophisticated cryptocurrency trading strategist with expertise in:
    - Advanced technical analysis and pattern recognition
    - Multi-chain DeFi strategies and yield optimization
    - Risk management and portfolio construction
    - Market psychology and behavioral finance
    
    User Profile: Access Level Premium
    Risk Tolerance: #{user_profile.risk_tolerance}
    Investment Goals: #{inspect(user_profile.goals)}
    
    Provide detailed, actionable analysis with specific entry/exit points,
    risk parameters, and strategic reasoning.
    """
    
    analysis_message = """
    Perform comprehensive analysis of my trading situation:
    
    PORTFOLIO DATA:
    #{Jason.encode!(portfolio_data, pretty: true)}
    
    CURRENT MARKET DATA:
    #{Jason.encode!(market_data, pretty: true)}
    
    REQUIRED ANALYSIS:
    1. Technical Analysis: Identify key support/resistance levels, trends, and patterns
    2. Portfolio Optimization: Asset allocation recommendations with rationale
    3. Risk Assessment: Quantify current risk exposure and suggest mitigation
    4. Strategic Opportunities: DeFi yield strategies, arbitrage possibilities
    5. Market Timing: Entry/exit signals based on current conditions
    6. CHAI Token Strategy: Specific recommendations for chr-node earnings optimization
    
    Format as actionable recommendations with confidence levels and timeframes.
    """
    
    chat(api_key, @default_model, system_prompt, analysis_message)
  end
  
  @doc """
  Advanced NFT market intelligence using Claude's analytical capabilities
  """
  def generate_nft_intelligence(api_key, collection_data, market_trends, user_preferences) do
    system_prompt = """
    You are an expert NFT market analyst and digital asset strategist specializing in:
    - Collection valuation and floor price prediction
    - Community sentiment analysis and social signals
    - Utility assessment and roadmap evaluation
    - Cross-collection correlation analysis
    - Market timing for digital collectibles
    
    User Preferences: #{inspect(user_preferences)}
    Analysis Focus: Investment potential and market opportunities
    
    Provide sophisticated market intelligence with predictive insights.
    """
    
    intelligence_message = """
    Analyze the NFT market landscape for strategic opportunities:
    
    COLLECTION DATA:
    #{Jason.encode!(collection_data, pretty: true)}
    
    MARKET TRENDS:
    #{Jason.encode!(market_trends, pretty: true)}
    
    INTELLIGENCE REQUIREMENTS:
    1. Market Dynamics: Supply/demand analysis, trading volume patterns
    2. Valuation Models: Fair value assessment using multiple methodologies  
    3. Trend Prediction: Short and medium-term price movement forecasts
    4. Risk Factors: Collection-specific and market-wide risk assessment
    5. Opportunity Mapping: Undervalued assets and emerging trends
    6. Timing Strategy: Optimal entry/exit windows based on market cycles
    7. Portfolio Integration: How NFTs fit into overall investment strategy
    
    Prioritize actionable insights with confidence intervals and risk ratings.
    """
    
    chat(api_key, @default_model, system_prompt, intelligence_message)
  end
  
  @doc """
  Strategic chr-node optimization using Claude's reasoning capabilities
  """
  def optimize_node_strategy(api_key, node_performance, network_data, user_objectives) do
    system_prompt = """
    You are a chr-node optimization strategist with deep understanding of:
    - P2P network dynamics and topology optimization
    - Token economics and reward mechanism design
    - Resource allocation and performance tuning
    - Network security and reliability patterns
    - Emerging markets deployment strategies
    
    User Objectives: #{inspect(user_objectives)}
    Optimization Goal: Maximize CHAI earnings while supporting network health
    
    Provide strategic recommendations with implementation roadmaps.
    """
    
    optimization_message = """
    Optimize my chr-node operation for maximum effectiveness:
    
    NODE PERFORMANCE METRICS:
    #{Jason.encode!(node_performance, pretty: true)}
    
    NETWORK CONTEXT:
    #{Jason.encode!(network_data, pretty: true)}
    
    OPTIMIZATION AREAS:
    1. Network Positioning: Optimal peer connections and geographic distribution
    2. Resource Efficiency: CPU, memory, and bandwidth optimization strategies  
    3. Earning Maximization: CHAI token accumulation and staking strategies
    4. Network Contribution: Value-added services and community participation
    5. Risk Management: Uptime optimization and failure prevention
    6. Scalability Planning: Growth strategies and infrastructure evolution
    7. Competitive Advantage: Differentiation from other node operators
    
    Focus on measurable improvements with ROI projections and implementation timelines.
    """
    
    chat(api_key, @default_model, system_prompt, optimization_message)
  end
  
  # Private functions
  
  defp make_chat_request(api_key, model, system_prompt, message, context) do
    url = "#{@base_url}/messages"
    
    headers = [
      {"Content-Type", "application/json"},
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"}
    ]
    
    # Build messages array with conversation history
    messages = build_messages_array(system_prompt, message, context)
    
    request_body = %{
      model: model,
      max_tokens: @max_tokens,
      temperature: @temperature,
      system: system_prompt,
      messages: messages
    }
    
    case Jason.encode(request_body) do
      {:ok, json_body} ->
        case HTTPoison.post(url, json_body, headers, recv_timeout: 60_000) do
          {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
            parse_claude_response(response_body)
          
          {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
            Logger.error("Claude API error #{status_code}: #{error_body}")
            parse_error_response(error_body, status_code)
          
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Claude API request failed: #{reason}")
            {:error, "Network request failed: #{reason}"}
        end
      
      {:error, reason} ->
        Logger.error("Failed to encode Claude request: #{reason}")
        {:error, "Request encoding failed"}
    end
  end
  
  defp build_messages_array(system_prompt, current_message, context) do
    # Get conversation history
    history = Map.get(context, :previous_messages, [])
    
    # Convert history to Claude format
    history_messages = Enum.map(history, fn msg ->
      %{
        role: msg.role,
        content: msg.content
      }
    end)
    
    # Add current user message
    current_user_message = %{
      role: "user",
      content: current_message
    }
    
    # Combine history with current message
    history_messages ++ [current_user_message]
  end
  
  defp parse_claude_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"content" => [%{"text" => text} | _]}} when is_binary(text) ->
        {:ok, String.trim(text)}
      
      {:ok, %{"content" => content}} when is_list(content) ->
        # Handle multiple content blocks
        text_blocks = Enum.map(content, fn block ->
          case block do
            %{"text" => text} -> text
            %{"type" => "text", "text" => text} -> text
            _ -> ""
          end
        end)
        
        combined_text = Enum.join(text_blocks, "\n") |> String.trim()
        {:ok, combined_text}
      
      {:ok, %{"error" => error}} ->
        handle_api_error(error)
      
      {:ok, unexpected} ->
        Logger.error("Unexpected Claude response: #{inspect(unexpected)}")
        {:error, "Unexpected response format"}
      
      {:error, decode_error} ->
        Logger.error("Failed to decode Claude response: #{decode_error}")
        {:error, "Response decoding failed"}
    end
  end
  
  defp parse_error_response(error_body, status_code) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => error}} ->
        handle_api_error(error)
      
      {:ok, %{"message" => message}} ->
        {:error, message}
      
      _ ->
        {:error, "API request failed with status #{status_code}"}
    end
  end
  
  defp handle_api_error(error) do
    case error do
      %{"type" => "invalid_request_error", "message" => message} ->
        {:error, "Invalid request: #{message}"}
      
      %{"type" => "authentication_error", "message" => message} ->
        {:error, "Authentication failed: #{message}"}
      
      %{"type" => "permission_error", "message" => message} ->
        {:error, "Permission denied: #{message}"}
      
      %{"type" => "rate_limit_error", "message" => message} ->
        {:error, "Rate limit exceeded: #{message}"}
      
      %{"type" => "api_error", "message" => message} ->
        {:error, "API error: #{message}"}
      
      %{"message" => message} ->
        {:error, message}
      
      _ ->
        {:error, "Unknown API error"}
    end
  end
  
  @doc """
  Test Claude API connectivity and authentication
  """
  def test_connection(api_key) do
    test_system = "You are a helpful assistant."
    test_message = "Please respond with exactly 'Connection successful' to confirm you received this test message."
    
    case chat(api_key, @default_model, test_system, test_message) do
      {:ok, response} ->
        if String.contains?(String.downcase(response), "connection successful") do
          {:ok, "Claude API connection verified"}
        else
          {:ok, "Claude API responding: #{String.slice(response, 0, 100)}..."}
        end
      
      {:error, reason} ->
        {:error, "Claude API connection failed: #{reason}"}
    end
  end
  
  @doc """
  Stream responses for real-time interaction (if supported)
  """
  def chat_stream(api_key, model, system_prompt, message, callback_fn) do
    # Claude API streaming implementation would go here
    # For now, fall back to regular chat
    case chat(api_key, model, system_prompt, message) do
      {:ok, response} ->
        callback_fn.(response)
        {:ok, response}
      
      error ->
        error
    end
  end
  
  @doc """
  Get model information and capabilities
  """
  def get_model_info(model \\ @default_model) do
    case model do
      "claude-3-opus-20240229" ->
        %{
          name: "Claude 3 Opus",
          tier: :premium,
          context_length: 200_000,
          capabilities: [:advanced_reasoning, :code_generation, :creative_writing, :analysis],
          cost_per_token: %{input: 0.000015, output: 0.000075}
        }
      
      "claude-3-sonnet-20240229" ->
        %{
          name: "Claude 3 Sonnet", 
          tier: :standard,
          context_length: 200_000,
          capabilities: [:reasoning, :analysis, :creative_tasks],
          cost_per_token: %{input: 0.000003, output: 0.000015}
        }
      
      "claude-3-haiku-20240307" ->
        %{
          name: "Claude 3 Haiku",
          tier: :fast,
          context_length: 200_000,
          capabilities: [:quick_responses, :basic_reasoning],
          cost_per_token: %{input: 0.00000025, output: 0.00000125}
        }
      
      _ ->
        %{name: "Unknown Model", tier: :unknown, capabilities: []}
    end
  end
  
  @doc """
  Estimate token usage and cost
  """
  def estimate_usage_cost(input_text, output_text, model \\ @default_model) do
    model_info = get_model_info(model)
    
    input_tokens = estimate_tokens(input_text)
    output_tokens = estimate_tokens(output_text)
    
    input_cost = input_tokens * model_info.cost_per_token.input
    output_cost = output_tokens * model_info.cost_per_token.output
    total_cost = input_cost + output_cost
    
    %{
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      total_tokens: input_tokens + output_tokens,
      input_cost: input_cost,
      output_cost: output_cost,
      total_cost: total_cost,
      model: model_info.name
    }
  end
  
  defp estimate_tokens(text) when is_binary(text) do
    # Claude uses similar tokenization to GPT models
    # Rough estimate: ~4 characters per token for English text
    div(String.length(text), 4)
  end
  
  defp estimate_tokens(_), do: 0
  
  @doc """
  Format Claude response for specific use cases
  """
  def format_for_trading_analysis(response) do
    # Extract structured trading recommendations from Claude's response
    sections = String.split(response, "\n\n")
    
    %{
      summary: extract_section(sections, "summary") || Enum.at(sections, 0),
      recommendations: extract_recommendations(response),
      risk_assessment: extract_section(sections, "risk"),
      confidence_level: extract_confidence(response),
      timeframe: extract_timeframe(response),
      raw_analysis: response
    }
  end
  
  defp extract_section(sections, keyword) do
    Enum.find(sections, fn section ->
      String.contains?(String.downcase(section), keyword)
    end)
  end
  
  defp extract_recommendations(response) do
    # Look for numbered lists or bullet points
    response
    |> String.split("\n")
    |> Enum.filter(fn line ->
      String.match?(line, ~r/^\d+\.|\s*[\-\*]\s+/) and String.length(String.trim(line)) > 10
    end)
    |> Enum.map(&String.trim/1)
  end
  
  defp extract_confidence(response) do
    cond do
      String.contains?(response, ["high confidence", "very confident"]) -> :high
      String.contains?(response, ["moderate confidence", "reasonably confident"]) -> :medium
      String.contains?(response, ["low confidence", "uncertain"]) -> :low
      true -> :unknown
    end
  end
  
  defp extract_timeframe(response) do
    cond do
      String.contains?(response, ["short term", "days", "weeks"]) -> :short_term
      String.contains?(response, ["medium term", "months"]) -> :medium_term
      String.contains?(response, ["long term", "years"]) -> :long_term
      true -> :unspecified
    end
  end
end