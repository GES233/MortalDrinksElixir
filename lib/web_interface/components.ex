defmodule WebInterface.Components do
  use Phoenix.Component

  slot :inner_block, required: true
  def code(assigns) do
    ~H"""
    <div class="panel zone-code" id="panel-source">
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

  attr :level, :atom, values: [:info, :error, :warn, :debug]
  slot :inner_block, required: true
  def log_item(assigns) do
    extra_class = if !is_nil(assigns[:level]) do
      ["log-entry", Atom.to_string(assigns[:level])] |> Enum.join(" ")
    else
      "log-entry"
    end
    assigns = assign(assigns, log_class: extra_class)

    ~H"""
      <div class={@log_class}><%= render_slot(@inner_block) %></div>
    """
  end

  def log_entry(assigns) do
    ~H"""
    <div class="panel zone-logs" id="panel-logs">
      <div class="panel-header">// KERNEL_OUTPUT_BUFFER</div>
      <div class="panel-content" id="log-container">
      <%= for item <- @logs do %>
        <%= case item do %>
          <% {level, content} -> %>
            <.log_item level={level}>{content}</.log_item>
          <% content -> %>
            <.log_item>{content}</.log_item>
        <% end %>
      <% end %>
      </div>
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
