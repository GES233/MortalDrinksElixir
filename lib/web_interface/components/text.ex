defmodule WebInterface.Components.Text do
  use Phoenix.Component


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
            <div class="mb-1 pl-1 border-sky-900 border-l-2 border-solid">
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

end
