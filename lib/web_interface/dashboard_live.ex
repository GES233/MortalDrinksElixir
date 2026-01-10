defmodule WebInterface.DashboardLive do
  use Phoenix.LiveView

  alias WebInterface.Components

  def render(assigns) do
    ~H"""
    <Components.app>
      <!-- Left side -->
      <:code>
        <Components.panel header="// SOURCE_CODE">
          <Components.code>
            <%= Phoenix.HTML.raw(@code_snippet) %>
          </Components.code>
        </Components.panel>
      </:code>
      <:console>
        <Components.panel header="// KERNEL_OUTPUT_BUFFER">
        <Components.log_entry logs={[
          {"> System boot sequence initiated...", :info},
          {"> Loading world assets... OK", :info},
          {"> Warning: Emotion engine offline.", :warn},
          {"> Conductor ready.", :info}
        ]}/><!-- Mock log add phx-update="stream" -->
        </Components.panel>
      </:console>

      <!-- Right side -->
      <:visual>
        <Components.visual animation={@animation} />
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

  def handle_info({:logic_trace, status, u, v}, socket) do
    # 格式化变量显示
    u_str = inspect_term(u)
    v_str = inspect_term(v)

    {msg, color_class} = case status do
      :ok ->
        {"Unifying #{u_str} == #{v_str} ... OK", "text-green-400 border-green-800"}
      :fail ->
        {"Unifying #{u_str} == #{v_str} ... CONTRADICTION", "text-red-500 border-red-800"}
    end

    # 构建带样式的日志对象
    log_entry = %{
      id: System.unique_integer([:positive]),
      msg: msg,
      class: "font-mono text-xs border-l-2 pl-2 mb-1 #{color_class}"
    }

    # 只保留最近 15 条，制造滚屏效果
    new_logs = [log_entry | socket.assigns.logs] |> Enum.take(15)

    {:noreply, assign(socket, logs: new_logs)}
  end

  # 一个简单的测试剧本
  def handle_info(:start_thinking, socket) do
    alias MortalDrinksElixir.Logic, as: L

    Task.start(fn ->
      # 模拟歌词: "If I am a set of points" -> 尝试统一属性
      L.run(fn _q ->
        L.conj(
          L.eq(:me, :set_of_points), # 成功
          L.call_fresh(fn heart ->
             L.conj(
               L.eq(heart, :emotional_core), # 成功
               L.eq(heart, :void)            # 失败！产生矛盾
             )
          end)
        )
      end)
    end)

    {:noreply, socket}
  end

  defp inspect_term(%MortalDrinksElixir.Logic.Var{id: id}), do: "?var_#{id}"
  defp inspect_term(atom) when is_atom(atom), do: ":#{atom}"
  defp inspect_term(other), do: inspect(other)
end
