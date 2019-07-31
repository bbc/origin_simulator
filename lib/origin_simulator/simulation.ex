
defmodule OriginSimulator.Simulation do
  use GenServer

  alias OriginSimulator.{Payload,RoutingTable,Duration}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  def state(server, pattern) do
    GenServer.call(server, {:state, pattern})
  end

  def recipe(server) do
    GenServer.call(server, :recipe)
  end

  def add_recipe(server, new_recipe) do
    GenServer.call(server, {:add_recipe, new_recipe})
  end

  def stop do
    GenServer.stop(:simulation)
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    {:ok, %{ recipe: nil, recipe_stages: %{} }}
  end

  @impl true
  def handle_call({:state, pattern}, _from, state) do
     Map.get(state, :recipe_stages)
    |> Map.get(pattern)
    |> case do
         nil -> {:reply, {:error, "Cannot find the simulation data"}, state}
         stage  -> {:reply, {:ok, stage.status, stage.latency}, state}
       end
  end

  @impl true
  def handle_call(:recipe, _from, state) do
    {:reply, state.recipe, state}
  end

  @impl true
  def handle_call({:add_recipe, new_recipe}, _caller, state) do
    RoutingTable.update_routing_table(:routing_table, new_recipe)
    Payload.update_payloads(:payloads, new_recipe)

    Enum.each(new_recipe, fn route ->
      Enum.each(route.stages, fn stage ->
        Process.send_after(self(),
          {:update, {route.pattern, stage["status"], Duration.parse(stage["latency"])}},
          Duration.parse(stage["at"]))
      end)
    end)

    {:reply, :ok, %{state | recipe: new_recipe }}
  end

  @impl true
  def handle_info({:update, {pattern, status, latency}}, state) do
    updated_stages = Map.get(state, :recipe_stages)
    |> Map.put(pattern, %{status: status, latency: latency})
    {:noreply, Map.put(state, :recipe_stages, updated_stages)}
  end
end
