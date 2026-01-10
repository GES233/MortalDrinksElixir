defmodule WebInterface.DashboardLive do
  use Phoenix.LiveView

  alias WebInterface.Components

  def render(assigns) do
    ~H"""
    <Components.app>
      <:code>
        <Components.code id={"panel-source"}>
          <%= Phoenix.HTML.raw(@code_snippet) %>
        </Components.code>
      </:code>
      <:console>
        <Components.log_entry logs={[
          {"> System boot sequence initiated...", :info},
          {"> Loading world assets... OK", :info},
          {"> Warning: Emotion engine offline.", :warn},
          {"> Conductor ready.", :info}
        ]}/><!-- Mock log add phx-update="stream" -->
      </:console>
      <:visual>
        <Components.visual id={"panel-vis"} animation={@animation} />
      </:visual>
      <:lyrics>
        <Components.lyrics
          text={"Switch on the power line"}
          sub={"Remember to put on PROTECTION"}
        />
      </:lyrics>
      <:hud>
        <Components.hud items={
          [
            {"FPS:", "60.0"},
            {"TICK:", @tick},
            {"MEM:", @mem <> "MB"},
            {"NET:", "CONNECTED"}
            ]
          } />
      </:hud>
    </Components.app>
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
