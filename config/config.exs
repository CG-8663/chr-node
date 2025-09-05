# Chronara Node (chr-node) Configuration  
# Copyright 2021-2024 Diode (original), 2025 Chronara (enhancements)
# Licensed under the Diode License, Version 1.1
import Config

# Configures Elixir's Logger
config :logger,
  # handle_otp_reports: true,
  # handle_sasl_reports: true,
  backends: [:console],
  truncate: 8000,
  format: "$time $metadata[$level] $message"

config :logger, :console, format: "$time $metadata[$level] $message\n"

config :diode_client, :keccak_256, {:keccakf1600, :sha3_256}

if Mix.env() == :test do
  {_, _} = System.cmd("killall", ["anvil", "-w"])
  File.rm_rf("data_test")

  if System.get_env("RPC_PORT") == nil do
    System.put_env("RPC_PORT", "18001")
    System.put_env("EDGE2_PORT", "18003")
    System.put_env("PEER2_PORT", "18004")
  end
end

if Mix.env() != :test and File.exists?("config/chronara.exs") do
  import_config "chronara.exs"
end

config :exqlite, force_build: true
