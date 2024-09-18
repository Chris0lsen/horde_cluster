defmodule HordeCluster.Application do
  use Application

  def start(_type, _args) do
    # Fetch the cluster topology configuration
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      # Start libcluster for automatic node discovery
      {Cluster.Supervisor, [topologies, [name: HordeCluster.ClusterSupervisor]]},
      # Start the Horde Registry for worker registration
      {Horde.Registry,
       [
         name: HordeCluster.Registry,
         keys: :unique,
         members: :auto  # Automatically discover other registries
       ]},
      # Start the Horde supervisor
      {Horde.Supervisor,
       [
         name: HordeCluster.Supervisor,
         strategy: :one_for_one,
         members: :auto
       ]}
      # You can add other children here if needed
    ]

    # Start the supervision tree
    opts = [strategy: :one_for_one, name: HordeCluster.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    # Start workers under the Horde supervisor
    Enum.each(1..2, fn _ ->
      Horde.Supervisor.start_child(HordeCluster.Supervisor, {HordeCluster.Worker, []})
    end)

    {:ok, pid}
  end
end
