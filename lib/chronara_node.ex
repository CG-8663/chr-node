# Chronara Node (chr-node)
# Copyright 2021-2024 Diode (original), 2025 Chronara (enhancements)
# Licensed under the Diode License, Version 1.1
require Logger

defmodule ChronaraNode do
  use Application
  alias DiodeClient.{Hash, Object, Wallet}

  def start(type, args) do
    if Application.get_env(:chronara_node, :no_start) do
      Supervisor.start_link([], strategy: :rest_for_one, name: ChronaraNode.Supervisor)
    else
      do_start(type, args)
    end
  end

  @env Mix.env()
  @spec env :: :prod | :test | :dev
  def env() do
    :persistent_term.get(:env, @env)
  end

  defp do_start(_type, args) do
    :erlang.system_flag(:backtrace_depth, 30)
    ChronaraNode.Config.configure()

    puts("====== CHR-NODE ENV #{env()} ======")
    puts("Build       : #{ChronaraNode.Version.description()}")
    puts("Edge2   Port: #{Enum.join(edge2_ports(), ",")}")
    puts("Peer2   Port: #{peer2_port()}")
    puts("RPC     Port: #{rpc_port()}")
    puts("RPC SSL Port: #{rpcs_port()}")

    puts("Data Dir : #{data_dir()}")
    puts("Network  : Chronara Community Infrastructure")

    if System.get_env("COOKIE") do
      :erlang.set_cookie(String.to_atom(System.get_env("COOKIE")))
      puts("Cookie   : #{System.get_env("COOKIE")}")
    end

    # Remove old cache file if still present,
    # new file is at data_dir("remoterpc.cache")
    if File.exists?("remoterpc_cache") do
      File.rm("remoterpc_cache")
    end

    puts("")

    children =
      [
        Globals,
        Stats,
        {Exqlite.LRU, [name: Network.Stats.LRU, file_path: ChronaraNode.data_dir("network_stats.sq3")]},
        Network.Stats,
        supervisor(Model.Sql),
        TicketStore,
        Cron,
        supervisor(Channels),
        {PubSub, args},
        {Registry, keys: :duplicate, name: ChronaraNode.PubSub.Ticker},
        MerkleTree,
        supervisor(ClientBinaryStore),
        supervisor(Connection.Cache),
        supervisor(Connection.Pool),
        supervisor(RemoteChain.Supervisor),
        RemoteRpc,
        Connectivity,
        Object.Manager,
        Object.Server,
        # Supervisor below might crash this is on purpose, see restart: :temporary
        {Task.Supervisor, name: ChronaraNode.TaskSupervisor, restart: :temporary}
      ] ++
        List.flatten([
          Network.Server.child_specs(),
          if(Connectivity.port_open?(:peer2), do: Network.PeerHandler.child_spec()),
          if(Connectivity.port_open?(:rpc), do: Network.RpcHttp.child_spec()),
          if(Connectivity.port_open?(:rpcs), do: Network.RpcHttps.child_spec())
        ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: ChronaraNode.Supervisor]
    result = Supervisor.start_link(children, opts)

    case result do
      {:ok, _pid} ->
        Logger.info("🚀 Chronara Node started successfully - Community P2P Infrastructure")
        Logger.info("🔗 Connected to Chronara Network: #{chronara_network_info()}")
      error ->
        Logger.error("Failed to start ChronaraNode: #{inspect(error)}")
    end

    result
  end

  defp chronara_network_info() do
    "fleet.chronara.net (6 regional nodes)"
  end

  # Legacy Diode compatibility functions are implemented directly below

  # ChronaraNode-specific functions
  def data_dir() do
    case System.get_env("DATA_DIR") do
      nil -> "data"
      other -> other
    end
  end

  def data_dir(file) do
    Path.join([data_dir(), file])
  end

  def wallet() do
    Globals.get("wallet", fn ->
      wallet_file = data_dir("wallet.json")

      if File.exists?(wallet_file) do
        DiodeClient.Wallet.from_file(wallet_file)
      else
        wallet = DiodeClient.Wallet.new()
        DiodeClient.Wallet.to_file(wallet, wallet_file)
        wallet
      end
    end)
  end

  def node_address() do
    wallet() |> DiodeClient.Wallet.address!()
  end

  def miner() do
    Globals.get("miner", fn ->
      miner_file = data_dir("miner.json")

      if File.exists?(miner_file) do
        DiodeClient.Wallet.from_file(miner_file)
      else
        wallet = DiodeClient.Wallet.new()
        DiodeClient.Wallet.to_file(wallet, miner_file)
        wallet
      end
    end)
  end

  def node_self() do
    node_address() |> Hash.to_address()
  end

  def blockhash() do
    RemoteChain.RPCCache.peak_block_hash!(RemoteChain.diode_l1_fallback())
  end

  def ticket() do
    blockhash() |> TicketStore.ticket(node_address())
  end

  def serverid() do
    Hash.sha3_256("CHR-NODE:" <> Hash.to_hex(node_self())) |> DiodeClient.Base16.encode()
  end

  def address() do
    node_self()
  end

  def puts(msg) when is_binary(msg) do
    msg
    |> String.split("\n", trim: true)
    |> Enum.each(fn line ->
      IO.puts("#{DateTime.utc_now() |> DateTime.to_iso8601()} [CHR-NODE] #{line}")
    end)
  end

  def puts(msg) do
    puts("#{inspect(msg)}")
  end

  # Network configuration delegates
  defdelegate edge2_ports(), to: Network.Server
  defdelegate peer2_port(), to: Network.Server  
  defdelegate rpc_port(), to: Network.Server
  defdelegate rpcs_port(), to: Network.Server

  # Utility functions
  def supervisor(module) do
    {module, []}
  end
end