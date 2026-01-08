defmodule MortalDrinksElixir.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    Application.put_env(:mord_ex, MortalDrinksElixir.WebInterface.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      server: true,
      # It's only local deployed, so doen't matter.
      live_view: [signing_salt: "S=g%GZB}pGWvr4F?cj9BGgOpSQ!cc%&F"],
      secret_key_base: "tMUyLPVk8LAWZhQN5Ea47QJZh3iCfZpgk5wWrvimE0C1mEc7g4cLPNbtxxp0BP5d",
      pubsub_server: MortalDrinksElixir.PubSub,
      adapter: Bandit.PhoenixAdapter,
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
      MortalDrinksElixir.WebInterface.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MortalDrinksElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
