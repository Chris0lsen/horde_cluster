defmodule HordeCluster.Application do
  use Application

require Logger

  def start(_type, _args) do
    children = [
      # Start libcluster
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies), [name: HordeCluster.ClusterSupervisor]]},
      # Start the Horde Registry
      {Horde.Registry,
       [
         name: HordeCluster.Registry,
         keys: :unique,
         members: :auto
       ]},
      # Start the Horde DynamicSupervisor
      {Horde.DynamicSupervisor,
       [
         name: HordeCluster.DynamicSupervisor,
         strategy: :one_for_one,
         distribution_strategy: Horde.UniformQuorumDistribution,
         max_restarts: 100_000,
         max_seconds: 1,
         members: :auto
       ]}
    ]

    opts = [strategy: :one_for_one, name: HordeCluster.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end
