defmodule MortalDrinksElixir.WebInterface.Components do
  use Phoenix.Component

  attr :level, :atom, values: [:info, :error, :warn, :debug]
  attr :content, :string, required: true
  def log_item(assigns) do
    extra_class = if !is_nil(assigns[:level]) do
      ["log-entry", Atom.to_string(assigns[:level])] |> Enum.join(" ")
    else
      "log-entry"
    end
    assigns = assign(assigns, log_class: extra_class)

    ~H"""
      <div class={@log_class}><%= @content %></div>
    """
  end

  def log(assigns) do
    ~H"""
    <%= for item <- @logs do %>
      <%= case item do %>
        <% {level, content} -> %>
          <.log_item level={level} content={content} />
        <% content -> %>
          <.log_item content={content} />
      <% end %>
    <% end %>
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
