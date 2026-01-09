import Config

config :esbuild,
  version: "0.25.4",
  mord_ex: [
    args: ~w(js/app.js --bundle --target=es2022
      --outdir=../../../../priv/static/assets/js
      --external:/fonts/* --external:/images/*
      --alias:@=.),
    cd: Path.expand("lib/mortal_drinks_elixir/web_interface/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("deps", __DIR__), Mix.Project.build_path()]}
  ]

# config :phoenix_live_view, :colocated_js,
#       disable_symlink_warning: true

config :mord_ex, MortalDrinksElixir.WebInterface.Endpoint,
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
  ],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:mord_ex, ~w(--sourcemap=inline --watch)]},
    # tailwind: {Tailwind, :install_and_run, [:mord_ex, ~w(--watch)]}
  ]
