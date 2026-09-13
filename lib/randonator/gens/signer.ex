defmodule Randonator.Gens.Signer do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  # ---

  @impl true
  def init(_opts) do
    state = %{
      seed: nil,
      private_key: nil,
      public_key: nil,
      hash: nil,
      ttl: 16,
      allowed_misses: 32
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:rotate, state) do
    schedule_rotate()
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:new_seed, seed}, state) do
    {:noreply, Map.put(state, :seed, seed)}
  end

  defp schedule_rotate do
    Process.send_after(self(), :rotate, 10)
  end
end
