defmodule Randonator.Supervisors.ProviderSupervisor do
  @doc """
  Supervisor for Signing Providers
  """
  use DynamicSupervisor

  @max_providers Application.compile_env(:randonator, :max_providers, 10)

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_max_providers(), do: @max_providers
end
