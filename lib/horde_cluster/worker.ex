defmodule HordeCluster.Worker do
  use GenServer

  ## Client API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: via_tuple())
  end

  def via_tuple do
    {:via, Horde.Registry, {:worker, Node.self()}}
  end

  ## Server Callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call(:hello, _from, state) do
    node_name = Node.self() |> to_string()
    reply = {:ok, "#{node_name} says hello"}
    {:reply, reply, state}
  end

  # Optionally handle other messages
  def handle_call(_msg, _from, state) do
    {:reply, :unknown_message, state}
  end
end
