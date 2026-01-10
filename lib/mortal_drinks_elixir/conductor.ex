defmodule MortalDrinksElixir.Conductor do
  use GenServer
  require Logger

  # 130 BPM, 16th notes resolution
  # 60000 / 130 / 4 ≈ 115ms
  @tick_interval 115
  @topic "world_clock"

  # === Client API ===

  def start_link(_) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  # === Subscription ===

  def subscribe do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    {:noreply, %{state | subscribers: [pid | state.subscribers]}}
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
