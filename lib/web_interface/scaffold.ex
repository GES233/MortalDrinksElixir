defmodule WebInterface.Scaffold do
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
            --panel-border: 2px solid #333;
            --panel-active: 2px solid #00ff41;
          }

          body {
            font-family: 'Fira Code', 'Consolas', monospace;
            margin: 0;
            height: 100vh;
            overflow: hidden;
          }

          /* pre, code {
            font-family: "CaskaydiaCove Nerd Font Mono", Consolas, "Courier New", monospace;
            font-size: 14px; line-height: 1.4;
          } */

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

          .hud-wrapper {
            grid-template-columns: auto auto;
            gap: 2px 10px;
            line-height: 1.2;
            border-left: 1px solid #333;
            padding-left: 15px;
          }

          <%= Phoenix.HTML.raw(@makeup_style) %>

          /* Used for #f/#u/#s/#t in miniKanren */
          .zone-code .highlight .ss {
            background: #2aa198;
            border-radius: 4px;
            padding: 0 4px;
            font-weight: bold;
          }

          .zone-code .highlight .k, .kd {
            font-weight: bold;
          }

          .highlight { background: transparent !important; }
        </style>
        <link phx-track-static rel="stylesheet" href="/assets/css/app.css" />
        <script defer phx-track-static type="text/javascript" src="/assets/js/app.js"></script>
    </head>
      <body class="m-0 h-screen overflow-hidden text-phosphor-main bg-terminal-black font-lyrics">
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
