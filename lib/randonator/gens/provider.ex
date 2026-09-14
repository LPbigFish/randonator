defmodule Randonator.Gens.Provider do
  use GenServer

  def start_link(args = %{provider_name: provider_name, init_seed: _init_seed}) do
    GenServer.start_link(__MODULE__, args, name: via(provider_name))
  end

  # ---

  @impl true
  def init(%{init_seed: seed, provider_name: name}) do
    {pub, priv} = Randonator.ECDSA.create_keypair()

    state = %{
      provider_name: name,
      seed: seed,
      private_key: priv,
      public_key: pub,
      hash: nil,
      ttl: 16,
      allowed_misses: 32
    }

    {:ok, state}
  end

  defp via(name) do
    {:via, Registry, {Randonator.ProviderRegistry, name}}
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
