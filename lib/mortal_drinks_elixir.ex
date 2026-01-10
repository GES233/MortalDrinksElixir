defmodule MortalDrinksElixir do
  @moduledoc """

  The program MortalDrinksElixir implements an application that
  provide a playground to simulate a world without meaning, and the
  only purpose is to generate vivid stimulus(in `World`).
  """
  use Application

  def start(_start_type, _start_args) do
    # Load before Web interface activated.
    Makeup.Registry.register_lexer(
      MakeupKanren,
      options: [], names: ["miniKanren", "mini_kanren", "Kanren"]
    )

    children = [
      MortalDrinksElixir.Conductor,
      # Communicate
      {Phoenix.PubSub, name: MortalDrinksElixir.PubSub},
      # WebUI
      WebInterface.Endpoint,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MortalDrinksElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
