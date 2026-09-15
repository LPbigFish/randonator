defmodule Randonator.Supervisors.ProviderSupervisorTest do
  use ExUnit.Case, async: false

  alias Randonator.ProviderRegistry
  alias Randonator.Supervisors.ProviderSupervisor

  test "application starts and populates the named provider registry and supervisor" do
    children = Supervisor.which_children(Randonator.Supervisor)

    registry_pid = Process.whereis(ProviderRegistry)
    supervisor_pid = Process.whereis(ProviderSupervisor)

    assert is_pid(registry_pid)
    assert is_pid(supervisor_pid)

    assert Enum.any?(children, fn
             {ProviderRegistry, ^registry_pid, :supervisor, [Registry]} -> true
             _child -> false
           end)

    assert Enum.any?(children, fn
             {ProviderSupervisor, ^supervisor_pid, :supervisor, [ProviderSupervisor]} -> true
             _child -> false
           end)

    for i <- 1..ProviderSupervisor.get_max_providers()//1 do
      assert [{_pid, nil}] = Registry.lookup(ProviderRegistry, "provider_#{i}")
    end
  end

  test "spawns providers under the dynamic supervisor and registers them by name" do
    initial_count = DynamicSupervisor.count_children(ProviderSupervisor).active
    provider_name = unique_provider_name("registered")
    seed = "seed-123"

    assert {:ok, pid} =
             ProviderSupervisor.spawn_new_provider(%{
               provider_name: provider_name,
               init_seed: seed
             })

    terminate_provider_on_exit(pid)

    assert DynamicSupervisor.count_children(ProviderSupervisor).active == initial_count + 1
    assert [{^pid, nil}] = Registry.lookup(ProviderRegistry, provider_name)

    assert %{
             provider_name: ^provider_name,
             seed: ^seed,
             private_key: private_key,
             public_key: public_key,
             hash: nil,
             ttl: 16,
             allowed_misses: 32
           } = GenServer.call({:via, Registry, {ProviderRegistry, provider_name}}, :get_state)

    assert is_binary(private_key)
    assert is_binary(public_key)
  end

  test "rejects a second provider with the same registry name" do
    provider_name = unique_provider_name("duplicate")

    assert {:ok, pid} =
             ProviderSupervisor.spawn_new_provider(%{
               provider_name: provider_name,
               init_seed: "seed-1"
             })

    terminate_provider_on_exit(pid)

    assert {:error, {:already_started, ^pid}} =
             ProviderSupervisor.spawn_new_provider(%{
               provider_name: provider_name,
               init_seed: "seed-2"
             })

    assert [{^pid, nil}] = Registry.lookup(ProviderRegistry, provider_name)
  end

  defp unique_provider_name(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  defp terminate_provider_on_exit(pid) do
    on_exit(fn ->
      ref = Process.monitor(pid)

      case DynamicSupervisor.terminate_child(ProviderSupervisor, pid) do
        :ok ->
          assert_receive {:DOWN, ^ref, :process, ^pid, _reason}

        {:error, :not_found} ->
          Process.demonitor(ref, [:flush])
      end
    end)
  end
end
