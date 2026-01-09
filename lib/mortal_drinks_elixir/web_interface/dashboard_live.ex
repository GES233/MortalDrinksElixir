defmodule MortalDrinksElixir.WebInterface.DashboardLive do
  use Phoenix.LiveView

  alias MortalDrinksElixir.WebInterface.Components

  def render(assigns) do
    ~H"""
    <div class="layout-grid">
      <div class="col-left">
        <Components.code>
          <%= Phoenix.HTML.raw(@code_snippet) %>
        </Components.code>
        <Components.log_entry logs={[
          "> System boot sequence initiated...",
          "> Loading world assets... OK",
          {:warn, "> Warning: Emotion engine offline."},
          "> Conductor ready."
        ]}/><!-- Mock log add phx-update="stream" -->
      </div>
      <div class="col-right">
        <div class="panel zone-vis" id="panel-vis"> <!-- phx-hook="DreamWorld" -->
          <div style="text-align: center;">
            <h1 style="font-size: 3rem; margin: 0;"><%= @animation %></h1>
            <p style="opacity: 0.6;">RENDERING VIEWPORT</p>
          </div>
        </div>
        <div class="panel zone-lyrics">
          <div class="lyrics-wrapper">
            <div class="lyric-text">Switch on the power line</div>
            <div class="lyric-sub">> Remember to put on PROTECTION</div>
          </div>
          <Components.hud items={
            [
              {"FPS:", "60.0"},
              {"TICK:", @tick},
              {"MEM:", @mem <> "MB"},
              {"NET:", "CONNECTED"}
              ]
            } />
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(MortalDrinksElixir.PubSub, "world_clock")

    code = """
    (defrel (appendo l s out)
      (condᵉ
        ((== '() l) (== s out))
        ((fresh (a d res)
          (== `(,a . ,d) l)
          (== `(,a . ,res) out)
          (appendo d s res)))))

    (run* (q) (appendo '(a b) '(c d) q))
    #f
    """

    {:ok,
     assign(socket,
       code_snippet: Makeup.highlight(code, lexer: MakeupKanren),
       status: "IDLE",
       tick: 0,
       animation: "(-_-)",
       mem:
         (:erlang.memory(:total) / 1000_000)
         |> Float.ceil(2)
         |> :erlang.float_to_binary([:short])
     )}
  end

  def handle_info({:tick, count}, socket) do
    frame = rem(count, 8)

    emoji =
      case frame do
        0 -> "(>_<)"
        1 -> "(o_o)"
        2 -> "(<_<)"
        3 -> "(o_o)"
        4 -> "(>_<)"
        5 -> "(o_o)"
        6 -> "(>_>)"
        7 -> "(o_o)"
      end

    {:noreply,
     assign(socket,
       tick: count,
       animation: emoji,
       mem:
         (:erlang.memory(:total) / 1000_000)
         |> Float.ceil(2)
         |> :erlang.float_to_binary([:short])
     )}
  end
end
