defmodule MortalDrinksElixir.WebInterface do
  @moduledoc """
  Embedd phoenix WebUI within a single module here.
  """

  defmodule DashboardLive do
    use Phoenix.LiveView, layout: {__MODULE__, :live}

    def render("live.html", assigns) do
      assigns =
        assign(assigns,
          makeup_style: :monokai_style |> Makeup.stylesheet() |> Phoenix.HTML.raw()
          # TODO: update
        )

      ~H"""
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
          <title>System Monitor</title>
          <style>
            :root {
              --phosphor-main: #00ff41;
              --phosphor-dim: #004411;
              --bg-color: #050505;
              --panel-border: 2px solid #333;
              --panel-active: 2px solid #00ff41;
            }

            body {
              background: var(--bg-color);
              color: var(--phosphor-main);
              font-family: 'Fira Code', 'Consolas', monospace;
              margin: 0;
              height: 100vh;
              overflow: hidden;
            }

            <%= Phoenix.HTML.raw(@makeup_style) %>

            pre, code {
              font-family: "CaskaydiaCove Nerd Font Mono", Consolas, "Courier New", monospace;
              font-size: 14px; line-height: 1.4;
            }

            .layout-grid {
              display: grid;
              grid-template-columns: 5fr 7fr;
              gap: 12px;
              height: 100vh;
              padding: 12px;
              box-sizing: border-box;
            }

            .col-left {
              display: grid;
              grid-template-rows: 1fr 1fr;
              gap: 12px;
              height: 100%;
              overflow: hidden;
            }

            .col-right {
              display: grid;
              grid-template-rows: 1fr 80px;
              gap: 12px;
              height: 100%;
              overflow: hidden;
            }

            .panel {
              border: var(--panel-border);
              background: rgba(0, 20, 0, 0.2);
              display: flex;
              flex-direction: column;
              position: relative;
            }

            .panel-header {
              background: #111;
              color: #888;
              padding: 5px 10px;
              font-size: 0.8rem;
              border-bottom: 1px dashed #333;
              flex-shrink: 0;
              text-transform: uppercase;
              letter-spacing: 1px;
              font-family: Consolas, 'Courier New', monospace;
            }

            .panel-content {
              padding: 10px;
              flex-grow: 1;
              overflow-y: auto;
              font-size: 14px;
              line-height: 1.5;
            }

            .zone-code pre { margin: 0; font-size: 12px; }

            .zone-logs { font-family: Consolas, 'Courier New', monospace; font-size: 12px; color: #aaa; }
            .log-entry { margin-bottom: 4px; border-left: 2px solid #333; padding-left: 5px; }
            .log-entry.warn { color: #ffff00; border-color: #ffff00; }
            .log-entry.err { color: #ff0000; border-color: #ff0000; }

            .zone-vis {
              border: var(--panel-active);
              justify-content: center;
              align-items: center;
              overflow: hidden;
            }

            .zone-lyrics {
              border: none;
              border-top: 2px solid var(--phosphor-main);
              background: #000;
              justify-content: center;
              align-items: center;
              text-align: center;
            }

              .lyric-text {
              font-size: 18px;
              font-weight: bold;
              color: #fff;
              text-shadow: 0 0 5px var(--phosphor-main);
            }

            .highlight { background: transparent !important; }
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
      <div class="layout-grid">

      <!-- LEFT COLUMN (5/12) -->
      <div class="col-left">

      <!-- TOP: SOURCE CODE (1:1) -->
      <div class="panel zone-code" id="panel-source">
        <div class="panel-header">// SOURCE_CODE</div>
        <div class="panel-content">
          <%= Phoenix.HTML.raw(@code_snippet) %>
        </div>
      </div>

      <!-- BOTTOM: SYSTEM LOGS (1:1) -->
      <div class="panel zone-logs" id="panel-logs">
        <div class="panel-header">// KERNEL_OUTPUT_BUFFER</div>
        <div class="panel-content" id="log-container">
          <!-- Mock log  phx-update="stream" -->
          <div class="log-entry">> System boot sequence initiated...</div>
          <div class="log-entry">> Loading world assets... OK</div>
          <div class="log-entry warn">> Warning: Emotion engine offline.</div>
          <div class="log-entry">> Conductor ready. Tick: <%= @tick %></div>
        </div>
      </div>

      </div>

      <!-- RIGHT COLUMN (7/12) -->
      <div class="col-right">

      <!-- TOP: VISUALIZATION (Main) -->
      <div class="panel zone-vis" id="panel-vis" phx-hook="DreamWorld">
        <div style="text-align: center;">
          <h1 style="font-size: 3rem; margin: 0;"><%= @animation %></h1>
          <p style="opacity: 0.6;">RENDERING VIEWPORT</p>
        </div>
      </div>

      <!-- BOTTOM: LYRICS (Fixed 80px) -->
      <div class="panel zone-lyrics">
        <div class="lyric-text">
          <div>Switch on the power line</div>
          <div style="font-size: 0.8em; opacity: 0.7;">Remember to put on PROTECTION</div>
        </div>
      </div>

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

      emoji =
        case frame do
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

    # When static resource is too large
    # apply Plug.Static

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
