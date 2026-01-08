defmodule MortalDrinksElixir.WebInterface do
  @moduledoc """
  Embedd phoenix WebUI within a single module here.
  """

  defmodule DashboardLive do
    use Phoenix.LiveView, layout: {__MODULE__, :live}

    def render("live.html", assigns) do
      ~H"""
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
          <title>System Monitor</title>
          <style>
            body { background: #000; color: #0f0; font-family: 'Courier New', monospace; margin: 0; padding: 20px; }
            .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; height: 95vh; }
            .panel { border: 2px solid #333; padding: 10px; overflow: hidden; }
            .active { border-color: #0f0; box-shadow: 0 0 10px #0f0; }
            pre {
              font-family: "CaskaydiaCove Nerd Font Mono", Consolas, "Courier New", monospace;
            }
          </style>
          <script src="https://cdn.jsdelivr.net/npm/phoenix@1.8.1/priv/static/phoenix.min.js"></script>
          <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@1.1.19/priv/static/phoenix_live_view.min.js"></script>
          <script>
            if (!window.liveSocket) {
              let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

              window.liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
                params: {_csrf_token: csrfToken}
              });

              window.liveSocket.connect();
              window.liveSocket.enableDebug();
            } else {
              window.liveSocket.connect();
              window.liveSocket.enableDebug();
            }
          </script>
      </head>
        <body>
          <%= @inner_content %>
        </body>
      </html>
      """
    end

    def render(assigns) do
      ~H"""
      <div class="grid">
        <div class="panel">
          <h3>// SOURCE_CODE</h3>
          <%= @code_snippet %>
        </div>
        <div class="panel active">
          <h3>// VISUALIZATION</h3>
          <p>Status: <%= @status %></p>
          <p>Tick: <%= @tick %></p>
        </div>
      </div>
      """
    end

    def mount(_params, _session, socket) do
      if connected?(socket),
        do: Phoenix.PubSub.subscribe(MortalDrinksElixir.PubSub, "world_clock")

      {:ok,
       assign(socket,
         code_snippet: Phoenix.HTML.raw("<pre>Loading...</pre>"),
         status: "IDLE",
         tick: 0
       )}
    end

    def handle_info({:tick, count}, socket) do
      {:noreply, assign(socket, tick: count)}
    end
  end

  defmodule Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
      plug(:put_root_layout, {DashboardLive, :live})
    end

    scope "/" do
      pipe_through(:browser)
      live("/", DashboardLive)
    end
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :mord_ex

    socket("/live", Phoenix.LiveView.Socket)

    plug(Plug.Session,
      store: :cookie,
      key: "_mortal_drinks_key",
      signing_salt: "SECRET_SALT_CHANGE_ME_PLEASE"
    )

    if code_reloading? do
      socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
      plug(Phoenix.LiveReloader)
      plug(Phoenix.CodeReloader)
    end

    plug(Router)
  end

  defmodule ErrorHTML do
    def render(template, _assigns) do
      Phoenix.Controller.status_message_from_template(template)
    end
  end
end
