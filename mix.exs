defmodule MortalDrinksElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mord_ex,
      version: "0.1.0",
      build_path: "_build",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MortalDrinksElixir, []}
    ]
  end

  defp deps do
    [
      ## Embedd Phoenix as UI
      # (not using it via `mix phx.new`)
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:bandit, "~> 1.10"},
      {:jason, "~> 1.4"},
      {:phoenix_live_reload, "~> 1.6"},

      ## Add code highlight
      {:makeup_elixir, "~> 1.0"},
      {:makeup, "~> 1.2"},
      # Used for build miniKanren lexers
      {:nimble_parsec, "~> 1.4"},
    ]
  end
end
