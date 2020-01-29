defmodule OriginSimulator.Simulation do
  use GenServer

  alias OriginSimulator.{Recipe, Payload, Duration}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  def state(server) do
    GenServer.call(server, :state)
  end

  def recipe(server) do
    GenServer.call(server, :recipe)
  end

  def route(server) do
    GenServer.call(server, :route)
  end

  # for now, deal with minimum viable recipe: list containing a single recipe
  def add_recipe(server, new_recipe) when is_list(new_recipe) and length(new_recipe) == 1 do
    GenServer.call(server, {:add_recipe, new_recipe |> hd})
  end

  # returning error, pending current work on multi-route / recipes
  def add_recipe(_server, new_recipe) when is_list(new_recipe), do: :error

  def add_recipe(server, new_recipe) do
    GenServer.call(server, {:add_recipe, new_recipe})
  end

  def restart do
    GenServer.stop(:simulation)
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    route = Recipe.default_route()
    state = default_simulation()

    # Simulation state data structure
    # %{"route1" => simulation_state1, "route2" => simulation_state2}
    {:ok, [{route, state}] |> Enum.into(%{})}
  end

  @impl true
  def handle_call(:state, _from, state) do
    [{_route, simulation}] = state |> Map.to_list()
    {:reply, {simulation.status, simulation.latency}, state}
  end

  @impl true
  def handle_call(:recipe, _from, state) do
    [{_route, simulation}] = state |> Map.to_list()
    {:reply, simulation.recipe, state}
  end

  @impl true
  def handle_call({:add_recipe, new_recipe}, _caller, state) do
    Payload.fetch(:payload, new_recipe)

    Enum.map(new_recipe.stages, fn item ->
      Process.send_after(
        self(),
        {:update, item["status"], Duration.parse(item["latency"])},
        Duration.parse(item["at"])
      )
    end)

    route = new_recipe.route
    simulation = get(state[route])

    {:reply, :ok, Map.put(%{}, route, %{simulation | recipe: new_recipe})}
  end

  @impl true
  def handle_call(:route, _from, state) do
    [{route, _simulation}] = state |> Map.to_list()
    {:reply, route, state}
  end

  @impl true
  def handle_info({:update, status, latency}, state) do
    [{route, simulation}] = state |> Map.to_list()
    {:noreply, Map.put(state, route, %{simulation | status: status, latency: latency})}
  end

  defp get(nil), do: default_simulation()
  defp get(current_state), do: current_state

  defp default_simulation(), do: %{recipe: nil, status: 406, latency: 0}
end
