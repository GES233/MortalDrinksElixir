defmodule MortalDrinksElixir.WebInterface.DashboardLive do
  use Phoenix.LiveView

  alias MortalDrinksElixir.WebInterface.Components

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
        <!-- Mock log add phx-update="stream" -->
        <Components.log logs={[
          "> System boot sequence initiated...",
          "> Loading world assets... OK",
          {:warn, "> Warning: Emotion engine offline."},
          "> Conductor ready."
        ]}/>
      </div>
    </div>

    </div>

    <!-- RIGHT COLUMN (7/12) -->
    <div class="col-right">

    <!-- TOP: VISUALIZATION (Main) -->
    <div class="panel zone-vis" id="panel-vis"> <!-- phx-hook="DreamWorld" -->
      <div style="text-align: center;">
        <h1 style="font-size: 3rem; margin: 0;"><%= @animation %></h1>
        <p style="opacity: 0.6;">RENDERING VIEWPORT</p>
      </div>
    </div>

    <!-- BOTTOM: LYRICS (Fixed 80px) -->
    <div class="panel zone-lyrics">
      <div class="lyrics-wrapper">
        <div class="lyric-text">Switch on the power line</div>
        <div class="lyric-sub">> Remember to put on PROTECTION</div>
      </div>

      <Components.hud items={
        [
          {"FPS:", "60.0"},
          {"TICK:", @tick},
          {"MEM:", "#{(:erlang.memory(:total) / 1000_000) |> Float.ceil(2) |> :erlang.float_to_binary([:short])}MB"},
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
    ; Comment
    (defrel (appendo l s out)
      (conde
        ((== '() l) (== s out))
        ((fresh (a d res)
          (== `(,a . ,d) l)
          (== `(,a . ,res) out)
          (appendo d s res)))))

    (run* (q) (appendo '(a b) '(c d) q))
    """

    {:ok,
     assign(socket,
       code_snippet: Makeup.highlight(code, lexer: MakeupKanren),
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
