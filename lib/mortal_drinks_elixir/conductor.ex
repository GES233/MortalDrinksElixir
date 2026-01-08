defmodule MortalDrinksElixir.Conductor do
  use GenServer
  require Logger

  @tick_interval 200
  @topic "world_clock"

  # === Client API ===

  def start_link(_) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  # === Server Callbacks ===

  @impl true
  def init(tick) do
    Logger.info("🎼 Conductor is raising the baton...")
    schedule_next_tick()
    {:ok, tick}
  end

  @impl true
  def handle_info(:perform_tick, tick) do
    Phoenix.PubSub.broadcast(MortalDrinksElixir.PubSub, @topic, {:tick, tick})

    schedule_next_tick()

    {:noreply, tick + 1}
  end

  defp schedule_next_tick do
    Process.send_after(self(), :perform_tick, @tick_interval)
  end
end
