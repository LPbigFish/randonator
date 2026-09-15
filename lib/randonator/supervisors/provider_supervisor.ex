defmodule Randonator.Supervisors.ProviderSupervisor do
  alias Randonator.Gens.ProviderGenServer

  @doc """
  Supervisor for Signing Providers
  """
  use DynamicSupervisor

  @max_providers Application.compile_env(:randonator, :max_providers, 10)
  @seed Application.compile_env(:randonator, :seed, 0)

  def start_link(init_arg) do
    seed = Keyword.get(init_arg, :seed, @seed)

    case DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__) do
      {:ok, pid} ->
        case populate(seed) do
          :ok ->
            {:ok, pid}

          {:error, _reason} = error ->
            Process.unlink(pid)
            Supervisor.stop(pid, :shutdown)
            error
        end

      {:error, _reason} = error ->
        error
    end
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_max_providers(), do: @max_providers

  @spec spawn_new_provider(%{provider_name: binary(), init_seed: binary()}) ::
          DynamicSupervisor.on_start_child()
  def spawn_new_provider(arg_map = %{provider_name: _, init_seed: _}),
    do:
      DynamicSupervisor.start_child(
        __MODULE__,
        {
          ProviderGenServer,
          arg_map
        }
      )

  @spec populate(binary()) :: :ok | {:error, tuple()}
  def populate(seed),
    do:
      Enum.reduce_while(1..@max_providers//1, :ok, fn i, :ok ->
        case spawn_new_provider(%{provider_name: "provider_#{i}", init_seed: seed}) do
          {:ok, _pid} -> {:cont, :ok}
          {:ok, _pid, _info} -> {:cont, :ok}
          :ignore -> {:halt, {:error, {:provider_ignored, i}}}
          {:error, reason} -> {:halt, {:error, {:provider_start_failed, i, reason}}}
        end
      end)
end
