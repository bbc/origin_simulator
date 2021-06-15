defmodule OriginSimulator.Simulation do
  @moduledoc """
  Server facilitating simulation recipe usage before and during load tests.
  """

  use GenServer

  alias OriginSimulator.{Recipe, Payload, Duration}

  @type latency :: integer()
  @type recipe :: OriginSimulator.Recipe.t()
  @type status :: integer()

  @type route :: binary()
  @type server :: :simulation | module()
  @type simulation_state :: %{required(:latency) => latency, required(:recipe) => recipe, required(:status) => status}

  ## Client API

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  @doc """
  Retrieve the simulation state for all routes.
  """
  @spec state(server) :: %{required(route) => simulation_state}
  def state(server) do
    GenServer.call(server, :state)
  end

  @doc """
  Retrieve the latency and status data for a specific route.

  ```
  iex> OriginSimulator.Simulation.state(:simulation, "/news")
  {200, 100}
  ```
  """
  @spec state(server, route) :: {status, latency}
  def state(server, route) do
    GenServer.call(server, {:state, route})
  end

  @doc """
  Retrieve all recipes uploaded to OriginSimulator.
  """
  @spec recipe(server) :: list(recipe)
  def recipe(server) do
    GenServer.call(server, :recipe)
  end

  @doc """
  Retrieve the recipe for a specific route.
  """
  @spec recipe(server, route) :: recipe
  def recipe(server, route) do
    GenServer.call(server, {:recipe, route})
  end

  @doc """
  Find a matching recipe route pattern for a given path.

  OriginSimulator is capable of serving multiple simulation recipes
  on multiple routes which could also be wildcard routes. For example:

  ```
  iex> OriginSimulator.Simulation.route(:simulation, "/news/weather")
  "/news*"
  ```

  The matching route is used for retrieving simulation state (latency, status)
  in `state/2`.
  """
  @spec route(server, route) :: route
  def route(server, route) do
    GenServer.call(server, {:route, route})
  end

  @doc """
  Retrieve a list of simulated routes.

  ```
  iex> OriginSimulator.Simulation.route(:simulation)
  ["/*", "/example/endpoint", "/news"]
  ```
  """
  @spec route(server, route) :: list(route)
  def route(server) do
    GenServer.call(server, :route)
  end

  @doc """
  Add a recipe or a list of recipes to the server.
  """
  @spec add_recipe(server, recipe | list(recipe)) :: :ok | :error
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

  @doc """
  Deletes simulation state including recipes and restart server.
  """
  @spec restart() :: :ok
  def restart do
    GenServer.stop(:simulation)
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    {:ok, %{Recipe.default_route() => default_simulation()}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:state, route}, _from, state) do
    {:reply, {state[route].status, state[route].latency}, state}
  end

  @impl true
  def handle_call({:recipe, route}, _from, state) do
    {:reply, state[route].recipe, state}
  end

  # retrieve all recipes
  @impl true
  def handle_call(:recipe, _from, state) do
    {
      :reply,
      Map.values(state)
      |> Enum.filter(&(&1.recipe != nil))
      |> Enum.map(& &1.recipe),
      state
    }
  end

  @impl true
  def handle_call({:add_recipe, new_recipe}, _caller, state) do
    Payload.fetch(:payload, new_recipe)

    route = new_recipe.route
    simulation = get(state[route])

    Enum.map(new_recipe.stages, fn item ->
      Process.send_after(
        self(),
        {:update, route, item["status"], Duration.parse(item["latency"])},
        Duration.parse(item["at"])
      )
    end)

    {:reply, :ok, Map.put(state, route, %{simulation | recipe: new_recipe})}
  end

  @impl true
  def handle_call({:route, route}, _from, state) do
    {:reply, match_route(state, state[route], route), state}
  end

  @impl true
  def handle_call(:route, _from, state), do: {:reply, state |> Map.keys(), state}

  @impl true
  def handle_info({:update, route, status, latency}, state) do
    {:noreply, Map.put(state, route, %{state[route] | status: status, latency: latency})}
  end

  defp get(nil), do: default_simulation()
  defp get(current_state), do: current_state

  defp default_simulation(), do: %{recipe: nil, status: 406, latency: 0}

  defp match_route(state, nil, route) do
    Map.keys(state)
    |> Enum.filter(&String.ends_with?(&1, "*"))
    |> match_wildcard_route(route)
  end

  defp match_route(_state, simulation, _route), do: simulation.recipe.route

  # find the nearest wildcard, e.g.
  # "/news/politics" matches "/news*" first, cf. "/*"
  # "/sport" matches "/*" not "/news*"
  defp match_wildcard_route(routes, route) do
    routes
    |> Enum.reverse()
    |> Enum.find(&matching_wildcard_route?(&1, route))
  end

  defp matching_wildcard_route?(r1, r2) do
    String.starts_with?(r2, String.trim(r1, "*"))
  end
end
