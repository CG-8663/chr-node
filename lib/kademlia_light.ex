# Diode Server
# Copyright 2021-2024 Diode
# Licensed under the Diode License, Version 1.1
defmodule KademliaLight do
  @moduledoc """
    KademliaLight.ex is in fact a K* implementation. K* star is a modified version of KademliaLight
    using the same KBuckets scheme to keep track of which nodes to remember. But instead of
    using the XOR metric it is using geometric distance on a ring as node value distance.
    Node distance is symmetric on the ring.

    KademliaLight is the kademllia graph for the light node protocol (PeerHandlerV2).
  """
  use GenServer
  alias Network.PeerHandlerV2
  alias DiodeClient.{Base16, ETSLru, Object, Object.Server, Wallet}
  alias Model.KademliaSql
  require Logger
  @k 3
  @storage_file "kademlia_light.etf"

  defstruct tasks: %{}, network: nil
  @type t :: %KademliaLight{tasks: map(), network: KBuckets.t()}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__, hibernate_after: 5_000)
  end

  @doc """
    store/1 same as store/2 but usees Object.key/1 and Object.encode/1
  """
  def store(object) when is_tuple(object) do
    key = Object.key(object)
    value = Object.encode!(object)
    store(key, value)
  end

  @doc """
    store() stores the given key-value pair in the @k nodes
    that are closest to the key
  """
  def store(key, value) when is_binary(value) do
    nodes =
      find_nodes(key)
      |> Enum.take(@k)

    # :io.format("Storing #{value} at ~p as #{Base16.encode(key)}~n", [Enum.map(nearest, &port/1)])
    rpc(nodes, [PeerHandlerV2.store(), hash(key), value])
  end

  @doc """
    find_value() is different from store() in that it might return
    an earlier result
  """
  def find_value(key) do
    key = hash(key)
    nodes = do_find_nodes(key, KBuckets.k(), PeerHandlerV2.find_value())

    case nodes do
      {:value, value, visited} ->
        result = KBuckets.nearest_n(visited, key, KBuckets.k())
        insert_nodes(visited)

        # Ensuring local database doesn't have anything older or newer
        value =
          with local_ret when local_ret != nil <- KademliaSql.object(key),
               local_block <- Object.block_number(Object.decode!(local_ret)),
               value_block <- Object.block_number(Object.decode!(value)) do
            if local_block < value_block do
              KademliaSql.put_object(key, value)
              value
            else
              with true <- local_block > value_block,
                   nearest when nearest != nil <- Enum.at(result, 0) do
                rpcast(nearest, [PeerHandlerV2.store(), key, local_ret])
              end

              local_ret
            end
          else
            _ -> value
          end

        # KademliaLight logic: Writing found result to second nearest node
        with second_nearest when second_nearest != nil <- Enum.at(result, 1) do
          rpcast(second_nearest, [PeerHandlerV2.store(), key, value])
        end

        value

      visited ->
        insert_nodes(visited)

        # We got nothing so far, trying local fallback
        local_ret = KademliaSql.object(key)

        if local_ret != nil do
          for node <- Enum.take(visited, 2) do
            rpcast(node, [PeerHandlerV2.store(), key, local_ret])
          end
        end

        local_ret
    end
  end

  @doc """
    find_node_object() is a buffed version of find_value()
    in that it first search in it's own kbuckets network
    and then secondly visits the value store
  """
  def find_node_object(address) do
    if address == Diode.address() do
      Diode.self()
    end ||
      case find_nodes(address) do
        [] ->
          nil

        [first | _] ->
          case Wallet.address!(first.node_id) do
            ^address -> KBuckets.object(first)
            _ -> nil
          end
      end ||
      with binary when is_binary(binary) <- find_value(address) do
        Object.decode!(binary)
      end
  end

  @doc """
    find_nodes() is following the kademlia paper 'find_node' algorithm.
    It returns the nodes that are closest to the given address.
  """
  def find_nodes(key) do
    key = hash(key)
    visited = do_find_nodes(key, KBuckets.k(), PeerHandlerV2.find_node())
    insert_nodes(visited)
    Enum.take(visited, KBuckets.k())
  end

  defp insert_nodes(visited) do
    before = network()

    network =
      Enum.reduce(visited, before, fn item, network ->
        if not KBuckets.member?(network, item) do
          KBuckets.insert_items(network, visited)
        else
          network
        end
      end)

    if before != network do
      GenServer.cast(__MODULE__, {:update_network, before, network})
    end

    visited
  end

  @doc """
  Retrieves for the target key either the last cached values or
  the nearest k entries from the KBuckets store
  """
  def find_node_lookup(key) do
    get_cached(&nearest_n/1, key)
  end

  def network() do
    call(fn _from, state -> {:reply, state.network, state} end)
  end

  @impl true
  def handle_call({:call, fun}, from, state) do
    fun.(from, state)
  end

  def handle_call({:append, key, value, _store_self}, _from, queue) do
    KademliaSql.append!(key, value)
    {:reply, :ok, queue}
  end

  @impl true
  def handle_info(:clean, state = %KademliaLight{network: network}) do
    # Remove all nodes who haven't connected in the last 30 hours
    deadline = System.os_time(:second) - 60 * 30

    stale =
      KBuckets.to_list(network)
      |> Enum.reject(fn n -> KBuckets.is_self(n) end)
      |> Enum.reject(fn n -> n.last_connected > deadline end)

    if length(stale) > 0 do
      network =
        Enum.reduce(stale, network, fn stale_node, network ->
          KBuckets.delete_item(network, stale_node)
        end)

      state = %{state | network: network}

      spawn(fn ->
        for stale_node <- stale, do: redistribute_stale(network, stale_node)
      end)

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_info(:save, state) do
    spawn(fn -> Model.File.store(Diode.data_dir(@storage_file), state, true) end)
    Process.send_after(self(), :save, 60_000)
    {:noreply, state}
  end

  def handle_info(:contact_seeds, state = %KademliaLight{network: network}) do
    for seed <- Diode.seeds() do
      %URI{userinfo: node_id, host: address, port: port} = URI.parse(seed)

      id =
        case node_id do
          nil -> Wallet.new()
          str -> Wallet.from_address(Base16.decode(str))
        end

      Network.Server.ensure_node_connection(PeerHandlerV2, id, address, port)
    end

    online = Network.Server.get_connections(PeerHandlerV2)
    now = System.os_time(:second)

    network =
      KBuckets.to_list(network)
      |> Enum.reduce(network, fn item = %KBuckets.Item{node_id: node_id}, network ->
        if not Map.has_key?(online, Wallet.address!(node_id)) do
          if next_retry(item) < now, do: ensure_node_connection(item)
          network
        else
          KBuckets.update_item(network, %KBuckets.Item{item | last_connected: now})
        end
      end)

    Process.send_after(self(), :contact_seeds, 60_000)
    {:noreply, %{state | network: network}}
  end

  @impl true
  def handle_continue(:seed, state) do
    Process.send_after(self(), :save, 60_000)
    handle_info(:contact_seeds, state)
    {:noreply, state}
  end

  def register_node(node_id, server) do
    Model.KademliaSql.maybe_update_object(nil, server)
    GenServer.cast(__MODULE__, {:register_node, node_id})
  end

  # Private call used by PeerHandlerV2 when connections are established
  @impl true
  def handle_cast({:register_node, node_id}, state) do
    case KBuckets.item(state.network, node_id) do
      nil -> {:noreply, do_register_node(state, node_id)}
      %KBuckets.Item{} -> {:noreply, state}
    end
  end

  # Private call used by PeerHandlerV2 when is stable for 10 msgs and 30 seconds
  def handle_cast({:stable_node, node_id}, state) do
    case KBuckets.item(state.network, node_id) do
      nil ->
        {:noreply, do_register_node(state, node_id)}

      %KBuckets.Item{} = node ->
        network = KBuckets.update_item(state.network, %KBuckets.Item{node | retries: 0})
        if node.retries > 0, do: queue_redistribute(network, node)
        {:noreply, %{state | network: network}}
    end
  end

  # Private call used by PeerHandlerV2 when connections fail
  def handle_cast({:failed_node, node}, state) do
    case KBuckets.item(state.network, node) do
      nil -> {:noreply, state}
      item -> {:noreply, %{state | network: do_failed_node(item, state.network)}}
    end
  end

  def handle_cast(
        {:update_network, before, new_network},
        state = %KademliaLight{network: network}
      ) do
    if before != network do
      Logger.warning("Race in KademliaLight.update_network()")
      {:noreply, state}
    else
      {:noreply, %{state | network: new_network}}
    end
  end

  defp do_register_node(state = %KademliaLight{network: network}, node_id) do
    node = %KBuckets.Item{
      node_id: node_id,
      last_connected: System.os_time(:second)
    }

    network = KBuckets.insert_item(network, node)

    # Because of bucket size limit, the new node might not get stored
    if KBuckets.member?(network, node_id) do
      queue_redistribute(network, node)
    end

    %{state | network: network}
  end

  defp next_retry(%KBuckets.Item{retries: failures, last_error: last}) do
    if failures == 0 or last == nil do
      -1
    else
      factor = min(failures, 7)
      last + round(:math.pow(5, factor))
    end
  end

  def rpc(nodes, call) when is_list(nodes) do
    me = self()
    ref = make_ref()

    Enum.map(nodes, fn node ->
      spawn_link(fn ->
        send(me, {ref, rpc(node, call)})
      end)
    end)
    |> Enum.map(fn _pid ->
      receive do
        {^ref, ret} ->
          ret
      end
    end)
  end

  def rpc(%KBuckets.Item{node_id: node_id} = node, call) do
    pid = ensure_node_connection(node)

    try do
      GenServer.call(pid, {:rpc, call}, 2000)
    rescue
      error ->
        Logger.warning(
          "Failed to get a result from #{Wallet.printable(node_id)} #{inspect(error)}"
        )

        []
    catch
      :exit, {:timeout, _} ->
        Debouncer.immediate(
          {:timeout, node_id},
          fn ->
            Logger.info("Timeout while getting a result from #{Wallet.printable(node_id)}")
          end,
          60_000
        )

        []

      :exit, {:normal, _} ->
        Debouncer.immediate(
          {:down, node_id},
          fn ->
            Logger.info(
              "Connection down while getting a result from #{Wallet.printable(node_id)}"
            )
          end,
          60_000
        )

        []

      any, what ->
        Logger.warning(
          "Failed(2) to get a result from #{Wallet.printable(node_id)} #{inspect({any, what})}"
        )

        []
    end
  end

  def rpcast(%KBuckets.Item{} = node, call) do
    GenServer.cast(ensure_node_connection(node), {:rpc, call})
  end

  defp queue_redistribute(network, node) do
    Debouncer.immediate(
      {:redistribute, node.node_id},
      fn -> redistribute(network, node) end,
      10_000
    )
  end

  #  redistribute resends all key/values that are nearer to the given node to
  #  that node
  @max_key 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
  defp redistribute(network, node) do
    online = Network.Server.get_connections(PeerHandlerV2)
    node = %KBuckets.Item{} = KBuckets.item(network, node)

    previ =
      case filter_online(KBuckets.prev(network, node), online) do
        [prev | _] -> KBuckets.integer(prev)
        [] -> KBuckets.integer(node)
      end

    nodei = KBuckets.integer(node)

    nexti =
      case filter_online(KBuckets.next(network, node), online) do
        [next | _] -> KBuckets.integer(next)
        [] -> KBuckets.integer(node)
      end

    range_start = rem(div(previ + nodei, 2), @max_key)
    range_end = rem(div(nexti + nodei, 2), @max_key)

    objs = KademliaSql.objects(range_start, range_end)
    Enum.each(objs, fn {key, value} -> rpcast(node, [PeerHandlerV2.store(), key, value]) end)
  end

  @doc """
    opposite operation of redistribute() resends all key/values belonged to a now missing
    node to the still existing neighbouring nodes
  """
  @max_key 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
  def redistribute_stale(network, %KBuckets.Item{} = node) do
    online = Network.Server.get_connections(PeerHandlerV2)

    {previ, prev} =
      case filter_online(KBuckets.prev(network, node), online) do
        [prev | _] -> {KBuckets.integer(prev), prev}
        [] -> {KBuckets.integer(node), nil}
      end

    nodei = KBuckets.integer(node)

    {nexti, next} =
      case filter_online(KBuckets.next(network, node), online) do
        [next | _] -> {KBuckets.integer(next), next}
        [] -> {KBuckets.integer(node), nil}
      end

    nodes = Enum.filter([prev, next], fn x -> x != nil end)

    if nodes != [] do
      range_start = rem(div(previ + nodei, 2), @max_key)
      range_end = rem(div(nexti + nodei, 2), @max_key)

      objs = KademliaSql.objects(range_start, range_end)

      for {key, value} <- objs do
        for node <- nodes do
          rpcast(node, [PeerHandlerV2.store(), key, value])
        end
      end
    end
  end

  # -------------------------------------------------------------------------------------
  # Helpers calls
  # -------------------------------------------------------------------------------------
  @impl true
  def init(:ok) do
    ETSLru.new(__MODULE__, 2048, fn value ->
      case value do
        nil -> false
        [] -> false
        _ -> true
      end
    end)

    kb =
      Model.File.load(Diode.data_dir(@storage_file), fn ->
        %KademliaLight{network: KBuckets.new()}
      end)

    for node <- KBuckets.to_list(kb.network) do
      if Map.has_key?(node, :object) and is_tuple(node.object) do
        KademliaSql.maybe_update_object(nil, node.object)
      end
    end

    # Clean dead nodes every 10 minutes
    :timer.send_interval(10 * 60 * 1000, :clean)

    {:ok, kb, {:continue, :seed}}
  end

  @doc "Method used for testing"
  def reset() do
    call(fn _from, _state ->
      {:reply, :ok, %KademliaLight{network: KBuckets.new()}}
    end)
  end

  def clean() do
    send(__MODULE__, :clean)
  end

  def append(key, value, store_self \\ false) do
    GenServer.call(__MODULE__, {:append, key, value, store_self})
  end

  # -------------------------------------------------------------------------------------
  # Private calls
  # -------------------------------------------------------------------------------------

  defp ensure_node_connection(item = %KBuckets.Item{node_id: node_id}) do
    if KBuckets.is_self(item) do
      Network.Server.ensure_node_connection(
        PeerHandlerV2,
        node_id,
        "localhost",
        Diode.peer2_port()
      )
    else
      server = KBuckets.object(item)
      host = Server.host(server)
      port = Server.peer_port(server)
      Network.Server.ensure_node_connection(PeerHandlerV2, node_id, host, port)
    end
  end

  defp do_failed_node(item = %KBuckets.Item{retries: retries}, network) do
    if KBuckets.is_self(item) do
      network
    else
      KBuckets.update_item(network, %KBuckets.Item{
        item
        | retries: retries + 1,
          last_error: System.os_time(:second)
      })
    end
  end

  def do_find_nodes(key, k, cmd) do
    get_cached(
      fn {cmd, key} ->
        KademliaSearch.find_nodes(__MODULE__, key, find_node_lookup(key), k, cmd)
      end,
      {cmd, key}
    )
  end

  def nearest_n(key) do
    KBuckets.nearest(network(), key)
    |> filter_online()
    |> Enum.take(KBuckets.k())
  end

  # If the list is external, we don't filter online because there is likely no connection
  def nearest_n(key, network) do
    KBuckets.nearest(network, key)
    |> Enum.take(KBuckets.k())
  end

  def filter_online(list, online \\ Network.Server.get_connections(PeerHandlerV2)) do
    Enum.filter(list, fn %KBuckets.Item{node_id: wallet} = item ->
      KBuckets.is_self(item) or Map.has_key?(online, Wallet.address!(wallet))
    end)
  end

  @cache_timeout 20_000
  defp get_cached(fun, key) do
    cache_key = {fun, key}

    case ETSLru.get(__MODULE__, cache_key) do
      nil ->
        ETSLru.fetch(__MODULE__, cache_key, fn -> fun.(key) end)

      other ->
        Debouncer.immediate(
          cache_key,
          fn -> ETSLru.put(__MODULE__, cache_key, fun.(key)) end,
          @cache_timeout
        )

        other
    end
  end

  defp call(fun) do
    GenServer.call(__MODULE__, {:call, fun})
  end

  def hash(binary) do
    Diode.hash(binary)
  end
end
