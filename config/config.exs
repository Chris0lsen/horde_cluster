import Config

config :libcluster,
  topologies: [
    local_gossip: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        # The multicast address used for node discovery
        multicast_addr: "239.1.1.251",
        # The multicast port (must be the same across all nodes)
        port: 45892,
        # Interface address to bind to (use "0.0.0.0" for all interfaces)
        if_addr: "0.0.0.0",
        # Multicast TTL (Time To Live)
        multicast_ttl: 1,
        # Gossip interval in milliseconds
        gossip_interval: 1_000,
        # Number of failures before node is considered unreachable
        max_convergence: 5
      ]
    ]
  ]
