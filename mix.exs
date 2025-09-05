# Chronara Node (chr-node)
# Copyright 2021-2024 Diode (original), 2025 Chronara (enhancements)
# Licensed under the Diode License, Version 1.1

if String.to_integer(System.otp_release()) < 25 do
  IO.puts("this package requires OTP 25.")
  raise "incorrect OTP"
end

defmodule ChronaraNode.Mixfile do
  use Mix.Project

  @url "https://github.com/CG-8663/chr-node"

  def project do
    {patches, description} =
      if File.exists?(".git") do
        patches = elem(System.cmd("git", ["log", "-100", "--oneline"]), 0) |> String.split("\n")
        description = elem(System.cmd("git", ["describe", "--tags"]), 0)
        {patches, description}
      else
        {[], "v0.0.0"}
      end

    vsn = Regex.run(~r/v([0-9]+\.[0-9]+\.[0-9]+)/, description) |> Enum.at(1)

    [
      aliases: aliases(),
      app: :chronara_node,
      compilers: Mix.compilers(),
      deps: deps(),
      description: "Chronara Network Lite Node - Community P2P Infrastructure",
      dialyzer: [plt_add_apps: [:mix]],
      docs: docs(vsn),
      elixir: "~> 1.15",
      elixirc_options: [warnings_as_errors: Mix.target() == :host],
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      releases: [
        chr_node: [
          applications: [runtime_tools: :permanent, ssl: :permanent],
          steps: [:assemble, :tar],
          version: vsn
        ]
      ],
      source_url: @url,
      start_permanent: Mix.env() == :prod,
      version: vsn,
      version_description: description,
      version_patches: patches
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [mod: {ChronaraNode, []}, extra_applications: [:logger, :observer, :runtime_tools]]
  end

  defp aliases do
    [
      lint: [
        "compile",
        "format --check-formatted",
        "credo --only warning",
        "dialyzer"
      ]
    ]
  end

  defp docs(vsn) do
    [
      source_ref: "v#{vsn}",
      source_url: @url,
      formatters: ["html"],
      main: "readme",
      extras: [
        LICENSE: [title: "License"],
        "README.md": [title: "Readme"]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Dominic Letz"],
      licenses: ["DIODE"],
      links: %{github: @url},
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp deps do
    [
      {:certmagex, "~> 1.0"},
      {:debouncer, "~> 0.1"},
      {:dets_plus, "~> 2.0"},
      {:eblake2, "~> 1.0"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:exqlite, github: "dominicletz/exqlite"},
      {:httpoison, "~> 2.0"},
      {:diode_client, github: "diodechain/diode_client_ex"},
      {:keccakf1600, github: "diodechain/erlang-keccakf1600"},
      {:libsecp256k1, "~> 0.1", hex: :libsecp256k1_diode_fork},
      {:oncrash, "~> 0.0"},
      {:plug_cowboy, "~> 2.5"},
      {:poison, "~> 6.0"},
      {:profiler, github: "dominicletz/profiler", override: true},
      {:websockex, "~> 0.5", hex: :websockex_wt},
      {:rotating_file, "~> 0.1"},

      # linting
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:while, "~> 0.2", only: [:test], runtime: false}
    ]
  end
end
