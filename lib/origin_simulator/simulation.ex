defmodule OriginSimulator.Simulation do
  use GenServer

  alias OriginSimulator.{Recipe, Payload, Duration}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  def state(server, route) do
    GenServer.call(server, {:state, route})
  end

  def recipe(server) do
    GenServer.call(server, :recipe)
  end

  def recipe(server, route) do
    GenServer.call(server, {:recipe, route})
  end

  def route(server, route) do
    GenServer.call(server, {:route, route})
  end

  def route(server) do
    GenServer.call(server, :route)
  end

  def add_recipe(server, recipes) when is_list(recipes) do
    resp =
      for recipe <- recipes do
        GenServer.call(server, {:add_recipe, recipe})
      end

    if Enum.all?(resp, &(&1 == :ok)), do: :ok, else: :error
  end

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
  def handle_call({:state, route}, _from, state) do
    simulation = state[route]
    {:reply, {simulation.status, simulation.latency}, state}
  end

  @impl true
  def handle_call({:recipe, route}, _from, state) do
    simulation = state[route]
    {:reply, simulation.recipe, state}
  end

  # retrieve all recipes
  @impl true
  def handle_call(:recipe, _from, state) do
    simulations = Map.values(state)

    recipes =
      simulations
      |> Enum.filter(&(&1.recipe != nil))
      |> Enum.map(& &1.recipe)

    {:reply, recipes, state}
  end

  @impl true
  def handle_call({:add_recipe, new_recipe}, _caller, state) do
    Payload.fetch(:payload, new_recipe)
    route = new_recipe.route

    Enum.map(new_recipe.stages, fn item ->
      Process.send_after(
        self(),
        {:update, route, item["status"], Duration.parse(item["latency"])},
        Duration.parse(item["at"])
      )
    end)

    simulation = get(state[route])
    {:reply, :ok, Map.put(state, route, %{simulation | recipe: new_recipe})}
  end

  @impl true
  def handle_call({:route, route}, _from, state) do
    recipe_route = match_route(state |> Map.keys(), route)
    {:reply, recipe_route, state}
  end

  @impl true
  def handle_call(:route, _from, state), do: {:reply, state |> Map.keys(), state}

  @impl true
  def handle_info({:update, route, status, latency}, state) do
    simulation = state[route]
    {:noreply, Map.put(state, route, %{simulation | status: status, latency: latency})}
  end

  defp get(nil), do: default_simulation()
  defp get(current_state), do: current_state

  defp default_simulation(), do: %{recipe: nil, status: 406, latency: 0}

  def match_route(routes, route) do
    case Enum.member?(routes, route) do
      true ->
        route

      false ->
        routes
        |> Enum.filter(&String.ends_with?(&1, "*"))
        |> match_wildcard_route(route)
    end
  end

  # find the nearest wildcard, e.g.
  # "/news/politics" matches "/news*" first, cf. "/*"
  # "/sport" matches "/*" not "/news*"
  defp match_wildcard_route(routes, route) do
    routes
    |> Enum.sort(&(&1 >= &2))
    |> Enum.find(&matching_wildcard_route?(&1, route))
  end

  defp matching_wildcard_route?(r1, r2) do
    String.starts_with?(r2, String.trim(r1, "*"))
  end
end
