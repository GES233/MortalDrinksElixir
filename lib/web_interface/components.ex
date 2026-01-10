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
    <div class="panel zone-code" id={@id}>
      <div class="panel-header">// SOURCE_CODE</div>
      <div class="panel-content" phx-look=".CodeLiveRenderer">
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
    <div class="panel zone-vis" id={@id}>
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
    <div class="panel zone-logs" id="panel-logs">
      <div class="panel-header">// KERNEL_OUTPUT_BUFFER</div>
      <div class="panel-content" id="log-container">
      <%= for item <- @logs do %>
        <%= case item do %>
          <% {content, nil} -> %>
            <div class="log-entry">{content}</div>
          <% {content, level} when is_atom(level) -> %>
            <div class={~w(log-entry #{Atom.to_string(level)})}>{content}</div>
          <% content -> %>
            <div class="log-entry">{content}</div>
        <% end %>
      <% end %>
      </div>
    </div>
    """
  end

  attr :text, :string
  attr :sub, :string
  def lyrics(assigns) do
    ~H"""
    <div class="lyrics-wrapper">
      <div class="lyric-text">{@text}</div>
      <div class="lyric-sub">&gt; {@sub}</div>
    </div>
    """
  end

  attr :items, :list, required: true
  def hud(assigns) do
    ~H"""
    <div class="hud-wrapper">
      <%= for {k, v} <- @items do %>
        <span class="hud-label">{k}</span>
        <span class="hud-value">{v}</span>
      <% end %>
      <div class="hud-item" style="grid-column: span 2; opacity: 0.5; margin-top: 3px;">
        0x4F 0x4B 0x00
      </div>
    </div>
    """
  end
end
