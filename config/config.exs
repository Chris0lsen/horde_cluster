config :libcluster,
  topologies: [
    horde_cluster: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:"ashbery@ashbery.local", :"bishop@bishop.local", :"creeley@creeley.local", :"dove@dove.local", :"emanuel@emanuel.local", :"ferlinghetti@ferlinghetti.local"]]
    ]
  ]
