defmodule MortalDrinksElixir.WebInterface do
  @moduledoc """
  Embedd phoenix WebUI here.
  """
  defmodule DashboardLive do
    use Phoenix.LiveView, layout: {__MODULE__, :live}

    # 简单的 CSS，模拟终端效果
    def render("live.html", assigns) do
      ~H"""
      <style>
        body { background: #000; color: #0f0; font-family: 'Courier New', monospace; margin: 0; padding: 20px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; height: 95vh; }
        .panel { border: 2px solid #333; padding: 10px; overflow: hidden; }
        .active { border-color: #0f0; box-shadow: 0 0 10px #0f0; }
      </style>
      <%= @inner_content %>
      """
    end

    def render(assigns) do
      ~H"""
      <div class="grid">
        <div class="panel">
          <h3>// SOURCE_CODE</h3>
          <pre><%= @code_snippet %></pre>
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
      # 订阅你的逻辑层广播
      if connected?(socket), do: Phoenix.PubSub.subscribe(MortalDrinksElixir.PubSub, "world_clock")

      {:ok, assign(socket, code_snippet: "Loading...", status: "IDLE", tick: 0)}
    end

    # 处理逻辑层发来的消息
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
      signing_salt: "SECRET_SALT_CHANGE_ME_PLEASE")

    plug(Router)
  end

  defmodule ErrorHTML do
    def render(template, _assigns) do
      Phoenix.Controller.status_message_from_template(template)
    end
  end
end
