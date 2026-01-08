defmodule MortalDrinksElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mord_ex,
      version: "0.1.0",
      build_path: "_build",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MortalDrinksElixir.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      ## Embedd Micro Phoenix
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:bandit, "~> 1.10"},
      {:jason, "~> 1.4"},
      {:phoenix_live_reload, "~> 1.6"}
    ]
  end
end
