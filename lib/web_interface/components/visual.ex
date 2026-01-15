defmodule WebInterface.Components.Visual do
  @moduledoc """
  Render dream, illusion or fantasy.
  """
  use Phoenix.Component

  @doc """
  Container of CYBERDREAM.
  """
  def visual(assigns) do
    ~H"""
      <div class="flex items-center">
        <canvas
          id="anime-entry"
          width="450" height="300"
          class="w-[640px] h-[400px] bg-terminal-black"
          style="image-rendering: pixelated; image-rendering: crisp-edges;"
          data-op="nil"
          phx-update="ignore"
          phx-hook="AnimeRenderer"
        >Canvas is not supported!</canvas>
      </div>
      <div class="font-anime text-center align-bottom">
        <p class="opacity-60 mt-3">RENDERING VIEWPORT</p>
      </div>
    """
  end
end
