# HordeCluster

## What is this

This repo is a testbed/playground for exploring building Elixir node clusters using Horde and libcluster. It should only be used as a reference, and not necessarily boilerplate for a production cluster, as it lacks amenities such as retry mechanisms, backpressure, error handling, and telemetry. It's just here to show off how simple it is to put together a cluster that uniformly distributes processes across all nodes on a network!

## What does it do

There are three important components to this project.

### Config

The project's configuration defines a topology for libcluster to use, in order to automatically `connect` to nodes on the network. The strategy used here is `Gossip`, which broadcasts on a multicast address and port, allowing newly-booted nodes on the network to find each other.

> Remember: Erlang nodes must share the same `cookie` in order to cluster with one another

I'm not an expert in Gossip or multicast DNS, but my understanding is that addresses within the 239.x.x.x block are administratively scoped, and not accessible on the broader internet, which seems like the solution you'd want for most projects.

### application.exs

The application file starts three children in its supervision tree:

1) libcluster itself, for connecting to the other nodes on the network
2) Horde.Registry, for registering nodes within the Horde cluster
  - Note that we configure the registry with `members: :auto`, so that all nodes in the cluster are added to the registry. 
3) Horde.DynamicSupervisor, for starting a new supervision tree on each node. Horde supervisors are distributed as well, so that if one ndoe fails, the supervision tree is uninterrupted.

### horde_cluster.ex

This comprises both the API (such as it is) and the job processor. It exposes two functions, `call_task/1` and `cast_task/1`. `call_task/1` is intended to represent synchronous job processing; a `Task` is started with `child_spec/1` and started somewhere in the Horde cluster with `Horde.DynamicSupervisor.start_child/2`. The function then awaits a response from the Task with `receive`, and returns the result to the caller.

The second public function is `cast_task/1`, which represents asynchronous stateless job processing. The main difference is that once the `child_spec` is started, we do not wait for a response, and instead immediately return `:ok` to the caller. This pattern could be used for longer-running tasks, or tasks that persist their results directly to a database.

There is also a private `do_work/1` function, which represents some work being done.

## How do I run it

I've been running `iex` instances in separate tab windows to simulate different hosts on a network. 

```
> iex --sname ashbery --cookie secret -S mix

> iex --sname bishop --cookie secret -S mix

> iex --sname creeley --cookie secret -S mix
```

... And then running an iex instance to represent a "caller".

```
> iex --sname ginsberg --cookie secret
```

And then on `ginsberg`, let's fire off some requests to our cluster and watch them get distributed:

```
# 1. Define the target node and task parameters
target_node = :"ashbery@Chriss-MacBook-Pro" # Replace this with your node@hostname
task_function = :call_task
task_args = [42]
total_tasks = 100

# 2. Submit 100 tasks and collect the results
results = Enum.map(1..total_tasks, fn _ ->
  :rpc.call(target_node, HordeCluster, task_function, task_args)
end)

# 3. Extract node names from the results
node_names = Enum.map(results, fn
  {:ok, %{node: node, result: _value}} -> node
  _ -> nil
end)

# 4. Count the number of tasks processed by each node
counts = Enum.frequencies(filtered_node_names)

# 5. Display the counts
IO.inspect(counts, label: "Tasks Processed by Each Node")
```

And you should see output similar to:

```
%{
  "ashbery@Chriss-MacBook-Pro": 31,
  "bishop@Chriss-MacBook-Pro": 37,
  "creeley@Chriss-MacBook-Pro": 32
}
```

Cool! RPC calls sent to one node in the cluster are distributed across all available nodes in the cluster. You can see how this could be useful if the "job" we were doing was more expensive.

## Thanks!

Thanks for taking a peek. This code went through a lot of iterations to make it as simple and lightweight as possible, for the purposes of showing off the bare minimum required to get a dynamic cluster of Erlang nodes all working together to handle a workload. There are a lot of options we have for building up from here:

 - GenServers instead of Tasks, for longer-lived, stateful process
 - leveraging DETS or mnesia for sharing state across the cluster
 - Adding Ecto and Repo to the cluster, so results can be written to a database
 - And so on...