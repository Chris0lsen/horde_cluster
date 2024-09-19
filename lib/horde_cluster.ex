defmodule HordeCluster do
  @moduledoc """
  Module for submitting tasks to the Horde cluster both synchronously and asynchronously.
  """

  require Logger

  # Synchronous task submission
  def call_task(task_data) do
    ref = make_ref()
    caller = self()

    # Define the function to perform the task and send the result back
    task_fun = fn ->
      result = do_work(task_data)
      send(caller, {ref, result})
    end

    # Create a child spec for the Task using Task.child_spec/1
    child_spec = Task.child_spec(fn -> task_fun.() end)

    # Assign a unique ID to prevent child spec conflicts
    child_spec = Map.put(child_spec, :id, {:task, ref})

    # Start the Task under Horde.DynamicSupervisor
    case Horde.DynamicSupervisor.start_child(HordeCluster.DynamicSupervisor, child_spec) do
      {:ok, _pid} ->
        # Wait for the result with a timeout (adjust as needed)
        receive do
          {^ref, result} ->
            {:ok, result}
        after
          5000 ->
            {:error, :timeout}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Asynchronous task submission
  def cast_task(task_data) do
    ref = make_ref()

    # Define the function to perform the task
    task_fun = fn ->
      do_work(task_data)
    end

    # Create a child spec for the Task using Task.child_spec/1
    child_spec = Task.child_spec(fn -> task_fun.() end)

    # Assign a unique ID to prevent child spec conflicts
    child_spec = Map.put(child_spec, :id, {:task, ref})

    # Start the Task under Horde.DynamicSupervisor
    case Horde.DynamicSupervisor.start_child(HordeCluster.DynamicSupervisor, child_spec) do
      {:ok, _pid} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Task processing logic
  defp do_work(task_data) do
    # Your task processing logic here
    result = task_data * 2
    node_name = node()
    
    # Log the result along with the node name
    Logger.info("Processed task #{inspect(task_data)} with result: #{inspect(result)} on node #{inspect(node_name)}")
    
    # Return the result and node name as a map
    %{result: result, node: node_name}
  end
end
