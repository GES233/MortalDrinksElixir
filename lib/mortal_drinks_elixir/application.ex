defmodule MortalDrinksElixir.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    Application.put_env(:mord_ex, MortalDrinksElixir.WebInterface.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      server: true,
      live_view: [signing_salt: "SECRET_SALT_CHANGE_ME"],
      secret_key_base: String.duplicate("a", 64),
      pubsub_server: MortalDrinksElixir.PubSub,
      adapter: Bandit.PhoenixAdapter,
      render_errors: [
        formats: [html: MortalDrinksElixir.WebInterface.ErrorHTML],
        layout: false
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
