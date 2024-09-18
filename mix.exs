defmodule HordeCluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :horde_cluster,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HordeCluster.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
defp deps do
  [
    {:horde, "~> 0.8"},
    {:libcluster, "~> 3.3"}
  ]
end

end
