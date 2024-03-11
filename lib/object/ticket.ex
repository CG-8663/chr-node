# Diode Server
# Copyright 2021 Diode
# Licensed under the Diode License, Version 1.1
defmodule Object.Ticket do
  require Record
  @behaviour Object

  Record.defrecord(:ticket,
    server_id: nil,
    chain_id: nil,
    block_number: nil,
    fleet_contract: nil,
    total_connections: nil,
    total_bytes: nil,
    local_address: nil,
    device_signature: nil,
    server_signature: nil
  )

  @type ticket ::
          record(:ticket,
            server_id: binary(),
            chain_id: binary(),
            block_number: integer(),
            fleet_contract: binary(),
            total_connections: integer(),
            total_bytes: integer(),
            local_address: binary(),
            device_signature: Secp256k1.signature(),
            server_signature: Secp256k1.signature() | nil
          )
  @type t ::
          record(:ticket,
            server_id: binary(),
            chain_id: binary(),
            block_number: integer(),
            fleet_contract: binary(),
            total_connections: integer(),
            total_bytes: integer(),
            local_address: binary(),
            device_signature: Secp256k1.signature(),
            server_signature: Secp256k1.signature() | nil
          )
  @impl true
  def key(tck = ticket()) do
    device_address(tck)
  end

  @impl true
  def valid?(_serv) do
    # validity is given by the correct key value
    true
  end

  def device_address(tck = ticket()) do
    Secp256k1.recover!(
      device_signature(tck),
      device_blob(tck),
      :kec
    )
    |> Wallet.from_pubkey()
    |> Wallet.address!()
  end

  def device_address?(tck = ticket(), wallet) do
    Secp256k1.verify(
      Wallet.pubkey!(wallet),
      device_blob(tck),
      device_signature(tck),
      :kec
    )
  end

  def device_sign(tck = ticket(), private) do
    ticket(tck, device_signature: Secp256k1.sign(private, device_blob(tck), :kec))
  end

  def server_sign(tck = ticket(), private) do
    ticket(tck, server_signature: Secp256k1.sign(private, server_blob(tck), :kec))
  end

  @doc """
    Format for putting into a transaction with "SubmitTicketRaw"
  """
  def raw(tck = ticket()) do
    [rec, r, s] = Secp256k1.bitcoin_to_rlp(device_signature(tck))

    [
      chain_id(tck),
      block_number(tck),
      fleet_contract(tck),
      server_id(tck),
      total_connections(tck),
      total_bytes(tck),
      Hash.sha3_256(local_address(tck)),
      r,
      s,
      rec
    ]
  end

  def device_blob(tck = ticket()) do
    # From DiodeRegistry.sol:
    #   bytes32[] memory message = new bytes32[](6);
    #   message[0] = blockhash(blockHeight);
    #   message[1] = bytes32(fleetContract);
    #   message[2] = bytes32(nodeAddress);
    #   message[3] = bytes32(totalConnections);
    #   message[4] = bytes32(totalBytes);
    #   message[5] = localAddress;
    [
      chain_id(tck),
      block_hash(tck),
      fleet_contract(tck),
      server_id(tck),
      total_connections(tck),
      total_bytes(tck),
      Hash.sha3_256(local_address(tck))
    ]
    |> Enum.map(&ABI.encode("bytes32", &1))
    |> :erlang.iolist_to_binary()
  end

  def server_blob(tck = ticket()) do
    [device_blob(tck), device_signature(tck)]
    |> :erlang.iolist_to_binary()
  end

  def epoch_length(), do: 2_592_000

  def time_to_epoch(timestamp) do
    rem(timestamp, epoch_length())
  end

  def server_id(ticket(server_id: id)), do: id
  def chain_id(ticket(chain_id: chain_id)), do: chain_id

  def epoch(ticket(chain_id: chain_id, block_number: n)),
    do: time_to_epoch(Chain.blocktime(chain_id, n))

  @impl true
  def block_number(ticket(block_number: n)), do: n
  def block_hash(ticket(chain_id: chain_id, block_number: n)), do: Chain.blockhash(chain_id, n)
  def device_signature(ticket(device_signature: signature)), do: signature
  def server_signature(ticket(server_signature: signature)), do: signature
  def fleet_contract(ticket(fleet_contract: fc)), do: fc
  def total_connections(ticket(total_connections: tc)), do: tc
  def total_bytes(ticket(total_bytes: tb)), do: tb
  def local_address(ticket(local_address: la)), do: la
end
