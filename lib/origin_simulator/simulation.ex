defmodule OriginSimulator.Simulation do
  use GenServer

  alias OriginSimulator.{Payload,Duration}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  def state(server, route) do
    GenServer.call(server, {:state, route})
  end

  def recipe_book(server) do
    GenServer.call(server, :recipe_book)
  end

  def add_recipe_book(server, new_recipe_book) do
    GenServer.call(server, {:add_recipe_book, new_recipe_book})
  end

  def restart do
    GenServer.stop(:simulation)
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    {:ok, %{ recipe_book: nil, recipe_stages: %{} }}
  end

  @impl true
  def handle_call({:state, route}, _from, state) do
    stage = Map.get(state, :recipe_stages)
    |> Map.get(route)

    case stage do
      nil -> {:reply, {:error}, state}
      _   -> {:reply, {:ok, stage.status, stage.latency}, state}
    end
  end

  @impl true
  def handle_call(:recipe_book, _from, state) do
    {:reply, state.recipe_book, state}
  end

  @impl true
  def handle_call({:add_recipe_book, new_recipe_book}, _caller, state) do
    Enum.each(new_recipe_book, fn recipe ->
      Payload.fetch(:payloads, recipe)
    end)

    Enum.map(new_recipe_book, fn recipe ->
      Enum.map(recipe.stages, fn stage ->
        Process.send_after(self(),
          {:update, {recipe.route, stage["status"], Duration.parse(stage["latency"])}},
          Duration.parse(stage["at"]))
      end)
    end)

    {:reply, :ok, %{state | recipe_book: new_recipe_book }}
  end

  @impl true
  def handle_info({:update, {route, status, latency}}, state) do
    updated_stages = Map.get(state, :recipe_stages)
    |> Map.put(route, %{status: status, latency: latency})
    {:noreply, Map.put(state, :recipe_stages, updated_stages)}
  end
end
