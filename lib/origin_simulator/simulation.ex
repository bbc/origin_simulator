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
    state = %{recipe: nil, status: 406, latency: 0}
    {:ok, {route, state}}
  end

  @impl true
  def handle_call(:state, _from, {route, state}) do
    {:reply, {state.status, state.latency}, {route, state}}
  end

  @impl true
  def handle_call(:recipe, _from, {route, state}) do
    {:reply, state.recipe, {route, state}}
  end

  @impl true
  def handle_call({:add_recipe, new_recipe}, _caller, {route, state}) do
    Payload.fetch(:payload, new_recipe)

    Enum.map(new_recipe.stages, fn item ->
      Process.send_after(
        self(),
        {:update, item["status"], Duration.parse(item["latency"])},
        Duration.parse(item["at"])
      )
    end)

    {:reply, :ok, {route, %{state | recipe: new_recipe}}}
  end

  @impl true
  def handle_call(:route, _from, {route, state}) do
    recipe = if state.recipe, do: state.recipe, else: %Recipe{}
    {:reply, recipe.route, {route, state}}
  end

  @impl true
  def handle_info({:update, status, latency}, {route, state}) do
    new_state = Map.merge(state, %{status: status, latency: latency})
    {:noreply, {route, new_state}}
  end
end
