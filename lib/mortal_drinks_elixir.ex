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

    Application.put_env(:mord_ex, MortalDrinksElixir.WebInterface.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      url: [host: "localhost"],
      check_origin: false,
      server: true,
      adapter: Bandit.PhoenixAdapter,
      # It's only local deployed, so doen't matter.
      live_view: [signing_salt: "S=g%GZB}pGWvr4F?cj9BGgOpSQ!cc%&F"],
      secret_key_base: "tMUyLPVk8LAWZhQN5Ea47QJZh3iCfZpgk5wWrvimE0C1mEc7g4cLPNbtxxp0BP5d",
      pubsub_server: MortalDrinksElixir.PubSub,
      render_errors: [
        formats: [html: MortalDrinksElixir.WebInterface.ErrorHTML],
        layout: false
      ],
      live_reload: [
        patterns: [
          ~r{static/.*(js|css|png|jpeg|jpg|gif)$},
          ~r{lib/mortal_drinks_elixir/.*(ex|exs)$}
        ]
      ]
    )

    children = [
      {Phoenix.PubSub, name: MortalDrinksElixir.PubSub},
      MortalDrinksElixir.Conductor,
      MortalDrinksElixir.WebInterface.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MortalDrinksElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
