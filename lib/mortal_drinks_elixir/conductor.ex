defmodule MortalDrinksElixir.Conductor do
  use GenServer
  require Logger

  # 130 BPM, 16th notes resolution
  # 60000 / 130 / 4 ≈ 115ms
  @tick_interval 115
  @topic "world_clock"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{tick: 0}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Logger.info("Conductor is raising the baton...")
    schedule_next_tick()
    {:ok, state}
  end

  @impl true
  def handle_info(:perform_tick, %{tick: tick} = state) do
    Phoenix.PubSub.broadcast(MortalDrinksElixir.PubSub, @topic, {:tick, tick})
    schedule_next_tick()
    {:noreply, %{state | tick: tick + 1}}
  end

  defp schedule_next_tick do
    Process.send_after(self(), :perform_tick, @tick_interval)
  end
end
