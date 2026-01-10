defmodule WebInterface.Components do
  use Phoenix.Component

  # === Scaffold ===

  slot :code
  slot :console
  slot :visual
  slot :lyrics
  slot :hud
  def app(assigns) do
    ~H"""
    <div class="grid grid-cols-[5fr_7fr] h-screen p-3 box-border gap-3">
      <div class="gap-3 grid grid-rows-[1fr_1fr] h-full overflow-hidden">
        <%= render_slot(@code) %>
        <%= render_slot(@console) %>
      </div>
      <div class="grid grid-rows-[1fr_100px] h-full overflow-hidden gap-3">
        <.panel focused={true} center={true}>
          <%= render_slot(@visual) %>
        </.panel>
          <div class="
              border-phosphor-main flex flex-row relative border-t-[2px_solid_var(--phosphor-main)]
              items-center text-center justify-between px-5 py-0 box-border w-full"
            >
            <%= render_slot(@lyrics) %>
            <%= render_slot(@hud) %>
          </div>
      </div>
    </div>
    """
  end

  # if
  # ture => border-phosphor-main
  # false => border-???
  attr :focused, :boolean, default: false
  attr :center, :boolean, default: false
  attr :header, :string, default: ""
  slot :inner_block, required: true
  def panel(assigns) do
    ~H"""
    <%= if not @center do %>
      <div class={["border-2 border-solid flex flex-col relative bg-[rgba(0,0,0,0.2)]", !@focused && "border-panel-border", @focused && "border-phosphor-main"]}>
        <%= if @header != "" do %>
          <div class="px-2.5 py-1.5 text-[0.8rem] border-b-[1px_dashed_#333] tracking-[1px] shrink-0 uppercase font-code text-gray-500 bg-[#111]">
            <%= @header %>
          </div>
        <% end %>
        <div class="p-2.5 grow overflow-y-auto leading-normal text-sm">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    <% else %>
      <div class="border-2 border-solid border-phosphor-main justify-center items-center overflow-hidden flex flex-col relative bg-[rgba(0,0,0,0.2)]">
        <%= render_slot(@inner_block) %>
      </div>
    <% end %>
    """
  end

  attr :id, :string
  slot :inner_block, required: true
  def code(assigns) do
    ~H"""
      <div class="text-sm leading-snug font-code my-0" phx-look=".CodeLiveRenderer">
        <%= render_slot(@inner_block) %>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".CodeLiveRenderer">
        export default {
          mounted() {}
        }
      </script>
    """
  end

  attr :animation, :string
  def visual(assigns) do
    ~H"""
    <div class="font-anime">
      <div style="text-align: center;">
        <h1 style="font-size: 3rem; margin: 0;"><%= @animation %></h1>
        <p style="opacity: 0.6;">RENDERING VIEWPORT</p>
      </div>
    </div>
    """
  end

  # TODO:
  # multi lines log(e.g. error stacktrace)
  def log_entry(assigns) do
    ~H"""
      <div class="p-2.5 grow overflow-y-auto leading-normal font-lyrics" id="log-container">
      <%= for item <- @logs do %>
        <div class="font-lyrics text-xs text-gray-400">
          <%= case item do %>
            <% {content, nil} -> %>
              <div class="mb-1 pl-1 border-l-2 border-solid border-gray-500">
                <%= content %>
              </div>
            <% {content, :info} -> %>
              <div class="mb-1 pl-1 border-sky-900 border-l-2 border-solid text-gray-400">
                <%= content %>
              </div>
            <% {content, :debug} -> %>
              <div class="mb-1 pl-1 border-sky-900 border-l-2 border-solid text-green-500">
                <%= content %>
              </div>
            <% {content, :warn} -> %>
              <div class="mb-1 pl-1 text-yellow-300 border-l-2 border-solid border-amber-700">
                <%= content %>
              </div>
            <% {content, :error} -> %>
              <div class="mb-1 pl-1 text-red-600 border-l-2 border-solid border-red-800">
                <%= content %>
              </div>
            <% content -> %>
              <div class="mb-1 pl-1 border-l-2 border-solid border-gray-500">
                <%= content %>
              </div>
          <% end %>
          </div>
        <% end %>
      </div>
    """
  end

  attr :text, :string
  attr :sub, :string
  def lyrics(assigns) do
    ~H"""
    <div class="text-left max-w-[70%] font-lyrics">
      <div class="text-white text-bold text-lg text-shadow-[0_0_5px_var(--phosphor-main)]">{@text}</div>
      <div class="opacity-70 text-xs mt-1">&gt; {@sub}</div>
    </div>
    """
  end

  attr :items, :list, required: true
  def hud(assigns) do
    ~H"""
    <div class="grid-cols-[auto_auto] gap-[2px 10px] leading-[1.2] border-l-[1px_solid_#333] font-anime text-right grid pl-4 text-[10px]">
      <%= for {k, v} <- @items do %>
        <span class="text-gray-600">{k}</span>
        <span class="text-phosphor-main">{v}</span>
      <% end %>
      <div class="contents text-phosphor-shadow mt-1 opacity-50 col-span-2">
        0x4F 0x4B 0x00
      </div>
    </div>
    """
  end
end
