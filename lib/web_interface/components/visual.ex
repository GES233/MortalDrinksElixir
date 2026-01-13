defmodule WebInterface.Components.Visual do
  @moduledoc """
  Render dream, illusion or fantasy.
  """
  use Phoenix.Component

  attr :animation, :string
  def visual(assigns) do
    ~H"""
      <div class="font-anime text-center">
      <h1 class="text-5xl"><%= @animation %></h1>
      <p class="opacity-60 mt-3">RENDERING VIEWPORT</p>
      </div>
    """
  end

  # 用于实现具体的效果
  # 遮罩（遮盖渲染画面的边缘；应用滤镜）
end
