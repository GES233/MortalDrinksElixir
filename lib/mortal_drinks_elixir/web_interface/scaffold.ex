defmodule MortalDrinksElixir.WebInterface.Scaffold do
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

          .zone-code .highlight .ss {
            background: #2aa198;
            border-radius: 4px;
            padding: 0 4px;
            font-weight: bold;
          }

          .zone-code .highlight .k, .kd {
            font-weight: bold;
          }

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
          .log-entry.info { color: #0000e0, border-color: #00405f }
          .log-entry.debug { color: #00ef00, border-color: #003f00 }
          .log-entry.warn { color: #ffff00; border-color: #5f3f00; }
          .log-entry.error { color: #ff0000; border-color: #7f0000; }

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
            align-items: center;
            text-align: center;

            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 20px;
            box-sizing: border-box;

            /* Solve the conflict with panel */
            flex-direction: row;
            width: 100%;
          }

          .lyric-text {
            font-size: 18px;
            font-weight: bold;
            color: #fff;
            text-shadow: 0 0 5px var(--phosphor-main);
          }

          .lyrics-wrapper {
            text-align: left; /* 左对齐 */
            max-width: 70%; /* 防止歌词太长撞到右边 */
          }

          .lyric-text {
            font-size: 18px;
            font-weight: bold;
            color: #fff;
            text-shadow: 0 0 5px var(--phosphor-main);
            line-height: 1.2;
          }

          .lyric-sub {
            font-size: 12px;
            color: var(--phosphor-main);
            opacity: 0.7;
            margin-top: 4px;
          }

          .hud-wrapper {
            text-align: right;
            font-family: 'Fira Code', 'Consolas', monospace;
            font-size: 10px;
            color: var(--phosphor-dim);
            display: grid;
            grid-template-columns: auto auto;
            gap: 2px 10px;
            line-height: 1.2;
            border-left: 1px solid #333;
            padding-left: 15px;
          }

          .hud-item { display: contents; }
          .hud-label { color: #555; }
          .hud-value { color: var(--phosphor-main); }

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
end
