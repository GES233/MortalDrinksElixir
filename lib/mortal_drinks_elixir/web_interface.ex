defmodule MortalDrinksElixir.WebInterface do
  @moduledoc """
  Embedd phoenix WebUI within a single module here.
  """

  defmodule DashboardLive do
    use Phoenix.LiveView, layout: {__MODULE__, :live}

    def render("live.html", assigns) do
      assigns =
        assign(assigns,
          makeup_style:
            :monokai_style |> Makeup.stylesheet() |> Phoenix.HTML.raw()
            # TODO: update
        )

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

            <%= Phoenix.HTML.raw(@makeup_style) %>

            pre, code {
              font-family: "CaskaydiaCove Nerd Font Mono", Consolas, "Courier New", monospace;
              font-size: 14px; line-height: 1.4;
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
          <%= Phoenix.HTML.raw(@code_snippet) %>
        </div>
        <div class="panel active">
          <h3>// VISUALIZATION</h3>
          <p>Status: <%= @status %></p>
          <p>Tick: <%= @tick %></p>
          <pre style="font-size: 20px; color: #ff00ff;"><%= @animation %></pre>
        </div>
      </div>
      """
    end

    def mount(_params, _session, socket) do
      if connected?(socket),
        do: Phoenix.PubSub.subscribe(MortalDrinksElixir.PubSub, "world_clock")

      code = """
      defmodule Foo do
        defstruct [:bar]
      end
      """

      {:ok,
       assign(socket,
         code_snippet: Makeup.highlight(code),
         status: "IDLE",
         tick: 0,
         animation: "(-_-)"
       )}
    end

    def handle_info({:tick, count}, socket) do
      frame = rem(count, 4)

      emoji = case frame do
        0 -> "(>_<)"
        1 -> "(o_o)"
        2 -> "(<_<)"
        3 -> "(o_o)"
      end

      {:noreply, assign(socket, tick: count, animation: emoji)}
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
