defmodule OriginSimulator.Simulation do
  use GenServer

  alias OriginSimulator.{Recipe, Payload, Duration, Simulation, Flakiness}

  defstruct latency: 0, payload_id: nil, recipe: nil, status: 406

  @type recipe :: OriginSimulator.Recipe.t()
  @type t :: %__MODULE__{
          latency: integer(),
          payload_id: binary(),
          recipe: recipe,
          status: integer()
        }

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  def new(), do: %Simulation{}

  def state(server) do
    GenServer.call(server, :state)
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
    {:ok, %{Recipe.default_route() => new()}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:state, route}, _from, state) do
    case state[route] do
      %{status: status, latency: latency, payload_id: payload_id} ->
        {:reply, {status, latency, payload_id}, state}

      nil ->
        {:reply, {406, 0, nil}, state}
    end
  end

  @impl true
  def handle_call({:recipe, route}, _from, state) do
    case state[route] do
      %{recipe: recipe} -> {:reply, recipe, state}
      nil -> {:reply, nil, state}
    end
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
        {:update, route, item["status"], Duration.parse(item["latency"]), route},
        Duration.parse(item["at"])
      )
    end)

    if auto_flakiness?(new_recipe), do: Flakiness.start(new_recipe, route)

    {:reply, :ok, Map.put(state, route, %{simulation | recipe: new_recipe})}
  end

  @impl true
  def handle_call({:route, route}, _from, state) do
    {:reply, match_route(state, state[route], route), state}
  end

  @impl true
  def handle_call(:route, _from, state), do: {:reply, state |> Map.keys(), state}

  @impl true
  def handle_info({:update, route, status, latency, payload_id}, state) do
    {:noreply, Map.put(state, route, %{state[route] | status: status, latency: latency, payload_id: payload_id})}
  end

  @impl true
  def handle_info({:update, {route, payload_id}}, state) do
    {:noreply, Map.put(state, route, %{state[route] | payload_id: {route, payload_id}})}
  end

  defp auto_flakiness?(%{random_content: nil}), do: false
  defp auto_flakiness?(%{random_content: value}), do: String.contains?(value, "..")
  defp auto_flakiness?(_other_recipe_type), do: false

  defp get(nil), do: new()
  defp get(current_state), do: current_state

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
