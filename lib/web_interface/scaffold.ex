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
