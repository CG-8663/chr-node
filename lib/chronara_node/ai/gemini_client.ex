defmodule ChronaraNode.AI.GeminiClient do
  @moduledoc """
  Google Gemini API Client for chr-node AI Agent Integration
  
  Handles communication with Google's Gemini AI API for personalized agent responses.
  Optimized for chr-node use cases with context-aware conversations.
  """
  
  require Logger
  
  @base_url "https://generativelanguage.googleapis.com/v1beta"
  @default_model "gemini-1.5-flash"
  @max_tokens 2048
  @temperature 0.7
  
  @doc """
  Send a chat message to Gemini API with system context
  """
  def chat(api_key, model \\ @default_model, system_prompt, message, context \\ %{}) do
    if is_nil(api_key) or String.length(api_key) == 0 do
      {:error, :api_key_not_configured}
    else
      make_chat_request(api_key, model, system_prompt, message, context)
    end
  end
  
  @doc """
  Generate trading insights using Gemini
  """
  def generate_trading_insights(api_key, portfolio_data, user_profile) do
    system_prompt = """
    You are an expert cryptocurrency trading advisor. Analyze the provided portfolio data 
    and generate personalized trading insights based on the user's profile and risk tolerance.
    
    User Profile: #{inspect(user_profile)}
    Current Time: #{DateTime.utc_now()}
    
    Provide specific, actionable recommendations with risk assessments.
    """
    
    portfolio_message = """
    Please analyze my current portfolio:
    #{Jason.encode!(portfolio_data, pretty: true)}
    
    Provide insights on:
    1. Portfolio balance and diversification
    2. Risk assessment
    3. Recommended actions (if any)
    4. Market opportunities
    5. chr-node/CHAI specific advice
    """
    
    chat(api_key, @default_model, system_prompt, portfolio_message)
  end
  
  @doc """
  Generate NFT market analysis using Gemini
  """
  def generate_nft_analysis(api_key, collection_data, market_preferences) do
    system_prompt = """
    You are an NFT market analyst with deep knowledge of blockchain collectibles, 
    market trends, and investment strategies. Focus on actionable insights.
    
    Market Preferences: #{inspect(market_preferences)}
    Analysis Time: #{DateTime.utc_now()}
    """
    
    analysis_message = """
    Analyze these NFT collections for investment potential:
    #{Jason.encode!(collection_data, pretty: true)}
    
    Provide analysis on:
    1. Collection floor price trends
    2. Trading volume patterns  
    3. Community strength indicators
    4. Investment risk assessment
    5. Recommended actions
    """
    
    chat(api_key, @default_model, system_prompt, analysis_message)
  end
  
  @doc """
  Get chr-node optimization suggestions
  """
  def get_node_optimization_advice(api_key, node_metrics, user_goals) do
    system_prompt = """
    You are a chr-node optimization expert. Analyze node performance metrics 
    and provide specific recommendations for improving earnings, connectivity, 
    and network contribution.
    
    User Goals: #{inspect(user_goals)}
    """
    
    optimization_message = """
    My chr-node metrics:
    #{Jason.encode!(node_metrics, pretty: true)}
    
    Help me optimize:
    1. Peer connections and network stability
    2. CHAI token earning potential  
    3. Resource usage efficiency
    4. Network contribution score
    5. Long-term sustainability
    """
    
    chat(api_key, @default_model, system_prompt, optimization_message)
  end
  
  # Private functions
  
  defp make_chat_request(api_key, model, system_prompt, message, context) do
    url = "#{@base_url}/models/#{model}:generateContent"
    
    headers = [
      {"Content-Type", "application/json"},
      {"x-goog-api-key", api_key}
    ]
    
    # Build conversation history from context
    conversation_history = build_conversation_history(context)
    
    # Combine system prompt with user message
    full_prompt = combine_prompts(system_prompt, message, conversation_history)
    
    request_body = %{
      contents: [
        %{
          parts: [
            %{text: full_prompt}
          ]
        }
      ],
      generationConfig: %{
        temperature: @temperature,
        maxOutputTokens: @max_tokens,
        topP: 0.95,
        topK: 64
      },
      safetySettings: [
        %{
          category: "HARM_CATEGORY_HARASSMENT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        %{
          category: "HARM_CATEGORY_HATE_SPEECH", 
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    }
    
    case Jason.encode(request_body) do
      {:ok, json_body} ->
        case HTTPoison.post(url, json_body, headers, recv_timeout: 30_000) do
          {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
            parse_gemini_response(response_body)
          
          {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
            Logger.error("Gemini API error #{status_code}: #{error_body}")
            {:error, "API request failed with status #{status_code}"}
          
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("Gemini API request failed: #{reason}")
            {:error, "Network request failed: #{reason}"}
        end
      
      {:error, reason} ->
        Logger.error("Failed to encode Gemini request: #{reason}")
        {:error, "Request encoding failed"}
    end
  end
  
  defp build_conversation_history(context) do
    case Map.get(context, :previous_messages) do
      nil -> []
      [] -> []
      messages when is_list(messages) ->
        Enum.take(messages, -5) # Last 5 messages for context
      _ -> []
    end
  end
  
  defp combine_prompts(system_prompt, user_message, conversation_history) do
    history_text = case conversation_history do
      [] -> ""
      history ->
        formatted_history = Enum.map(history, fn msg ->
          case msg do
            %{role: "user", content: content} -> "User: #{content}"
            %{role: "assistant", content: content} -> "Assistant: #{content}"
            _ -> ""
          end
        end)
        
        "\n\nPrevious conversation:\n" <> Enum.join(formatted_history, "\n") <> "\n\n"
    end
    
    """
    #{system_prompt}
    #{history_text}
    Current user message: #{user_message}
    
    Please provide a helpful, accurate response based on your role and the context provided.
    """
  end
  
  defp parse_gemini_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"candidates" => [candidate | _]}} ->
        case get_in(candidate, ["content", "parts"]) do
          [%{"text" => text} | _] when is_binary(text) ->
            {:ok, String.trim(text)}
          
          _ ->
            Logger.error("Unexpected Gemini response structure: #{inspect(candidate)}")
            {:error, "Invalid response format"}
        end
      
      {:ok, %{"error" => error}} ->
        error_message = get_in(error, ["message"]) || "Unknown API error"
        Logger.error("Gemini API error: #{error_message}")
        {:error, error_message}
      
      {:ok, unexpected} ->
        Logger.error("Unexpected Gemini response: #{inspect(unexpected)}")
        {:error, "Unexpected response format"}
      
      {:error, decode_error} ->
        Logger.error("Failed to decode Gemini response: #{decode_error}")
        {:error, "Response decoding failed"}
    end
  end
  
  @doc """
  Test API connectivity and authentication
  """
  def test_connection(api_key) do
    test_prompt = "Hello, please respond with 'Connection successful' if you receive this message."
    
    case chat(api_key, @default_model, "You are a helpful assistant.", test_prompt) do
      {:ok, response} ->
        if String.contains?(String.downcase(response), "connection successful") do
          {:ok, "Gemini API connection verified"}
        else
          {:ok, "Gemini API responding but unexpected response: #{response}"}
        end
      
      {:error, reason} ->
        {:error, "Gemini API connection failed: #{reason}"}
    end
  end
  
  @doc """
  Get available models (if supported by API)
  """
  def list_models(api_key) do
    url = "#{@base_url}/models"
    
    headers = [
      {"x-goog-api-key", api_key}
    ]
    
    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"models" => models}} ->
            model_list = Enum.map(models, fn model ->
              %{
                name: Map.get(model, "name"),
                display_name: Map.get(model, "displayName"),
                description: Map.get(model, "description")
              }
            end)
            {:ok, model_list}
          
          _ ->
            {:error, "Failed to parse models response"}
        end
      
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "API request failed with status #{status_code}"}
      
      {:error, reason} ->
        {:error, "Network request failed: #{reason}"}
    end
  end
  
  @doc """
  Calculate approximate token usage for cost estimation
  """
  def estimate_token_usage(text) when is_binary(text) do
    # Rough estimation: ~4 characters per token for English text
    div(String.length(text), 4)
  end
  
  def estimate_token_usage(_), do: 0
  
  @doc """
  Format response for different output types
  """
  def format_response(response, format \\ :text) do
    case format do
      :text -> response
      :markdown -> response  # Gemini often returns markdown-formatted text
      :json -> try_parse_json_response(response)
      _ -> response
    end
  end
  
  defp try_parse_json_response(response) do
    # Try to extract JSON from response if it contains structured data
    case Jason.decode(response) do
      {:ok, parsed} -> parsed
      {:error, _} -> %{content: response, format: "text"}
    end
  end
end