defmodule Randonator.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias Randonator.Supervisors.ProviderSupervisor

  use Application

  @seed Application.compile_env(:randonator, :seed, 0)

  @impl true
  def start(_type, _args) do
    children = [
      RandonatorWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:randonator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Randonator.PubSub},
      # Start a worker by calling: Randonator.Worker.start_link(arg)
      # {Randonator.Worker, arg},
      # Start to serve requests, typically the last entry
      {Registry, name: Randonator.ProviderRegistry, keys: :unique},
      {ProviderSupervisor, seed: @seed},
      RandonatorWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Randonator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RandonatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
