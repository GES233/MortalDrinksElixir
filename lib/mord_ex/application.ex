defmodule MortalDrinksElixir.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    children = [
      # Starts a worker by calling: VividPuppet.Worker.start_link(arg)
      # {VividPuppet.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VividPuppet.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
