defmodule WebInterface.Components do
  use Phoenix.Component

  slot :code
  slot :console
  slot :visual
  slot :lyrics
  slot :hud
  def app(assigns) do
    ~H"""
    <div class="grid grid-cols-[5fr_7fr] h-screen p-3 box-border gap-3 text-lyrics">
      <div class="gap-3 grid grid-rows-[1fr_1fr] h-full overflow-hidden">
        <%= render_slot(@code) %>
        <%= render_slot(@console) %>
      </div>
      <div class="grid grid-rows-[1fr_100px] h-full overflow-hidden gap-3">
          <%= render_slot(@visual) %>
          <div class="
              border-phosphor-main flex flex-row relative border-t-2 border-solid
              items-center text-center justify-between px-5 py-0 box-border w-full"
            >
            <%= render_slot(@lyrics) %>
            <%= render_slot(@hud) %>
          </div>
      </div>
    </div>
    """
  end

  attr :focused, :boolean, default: false
  attr :center, :boolean, default: false
  attr :header, :string, default: ""
  slot :inner_block, required: true
  def panel(assigns) do
    ~H"""
    <%= if not @center do %>
      <div class={[
          "border-2 border-solid flex flex-col relative bg-[rgba(0,0,0,0.2)]",
          !@focused && "border-panel-border", @focused && "border-phosphor-main"
        ]}>
        <%= if @header != "" do %>
          <div class="
              px-2.5 py-1.5 text-[0.8rem] border-b-2 border-dashed border-panel-border
              tracking-[1px] shrink-0 uppercase font-code text-gray-500 bg-panel-header"
            >
            <%= @header %>
          </div>
        <% end %>
        <div class="p-2.5 grow overflow-y-auto leading-normal text-sm">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    <% else %>
      <div class={[
          "border-2 border-solid justify-center items-center overflow-hidden
          flex flex-col relative bg-[rgba(0,0,0,0.2)]",
          !@focused && "border-panel-border", @focused && "border-phosphor-main"
        ]}>
        <%= render_slot(@inner_block) %>
      </div>
    <% end %>
    """
  end

  attr :items, :list, required: true
  def hud(assigns) do
    ~H"""
    <div class="grid-cols-[auto_auto] gap-[2px 10px] leading-[1.2] border-l-[1px_solid] border-panel-border font-anime text-right grid pl-4 text-[10px]">
      <%= for {k, v} <- @items do %>
        <span class="text-gray-600">{k}</span>
        <span class="text-phosphor-main">{v}</span>
      <% end %>
      <!-- Padding to align -->
      <span class="text-gray-600">----</span>
      <span class="text-gray-600">----------</span>
      <div class="contents text-phosphor-shadow mt-1 opacity-50 col-span-2">
        0x4F 0x4B 0x00
      </div>
    </div>
    """
  end
end
