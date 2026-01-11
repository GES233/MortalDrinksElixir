defmodule WebInterface.Scaffold do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  def render("live.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>System Monitor</title>
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
