defmodule WebInterface.Components do
  use Phoenix.Component

  slot :code
  slot :console
  slot :visual
  slot :lyrics
  slot :hud
  def app(assigns) do
    ~H"""
    <div class="layout-grid">
      <div class="col-left">
        <%= render_slot(@code) %>
        <%= render_slot(@console) %>
      </div>
      <div class="col-right">
        <%= render_slot(@visual) %>
        <div class="panel zone-lyrics">
        <%= render_slot(@lyrics) %>
        <%= render_slot(@hud) %>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string
  slot :inner_block, required: true
  def code(assigns) do
    ~H"""
    <div class="panel zone-code font-code" id={@id}>
      <div class="panel-header">// SOURCE_CODE</div>
      <div class="panel-content text-sm leading-snug font-code my-0" phx-look=".CodeLiveRenderer">
        <%= render_slot(@inner_block) %>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".CodeLiveRenderer">
        export default {
          mounted() {}
        }
      </script>
    </div>
    """
  end

  attr :id, :string
  attr :animation, :string
  def visual(assigns) do
    ~H"""
    <div class="panel zone-vis font-anime" id={@id}>
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
    <div class="panel zone-logs font-lyrics" id="panel-logs">
      <div class="panel-header">// KERNEL_OUTPUT_BUFFER</div>
      <div class="panel-content" id="log-container">
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
    <div class="hud-wrapper font-anime text-right grid pl-4 text-[10px]">
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
