defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Body, Recipe}

  @http_client Application.get_env(:origin_simulator, :http_client)

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  def fetch(server, %Recipe{origin: value, route: route}) when is_binary(value) do
    GenServer.call(server, {:fetch, value, route})
  end

  def fetch(server, %Recipe{body: value, route: route} = recipe) when is_binary(value) do
    GenServer.call(server, {:parse, recipe, route})
  end

  def fetch(server, %Recipe{random_content: value, route: route} = recipe)
      when is_binary(value) do
    GenServer.call(server, {:generate, recipe, route})
  end

  def body(_server, status, path \\ Recipe.default_route(), route \\ Recipe.default_route()) do
    case {status, path} do
      {200, _} -> cache_lookup(route)
      {404, _} -> {:ok, "Not found"}
      {406, "/*"} -> {:ok, OriginSimulator.recipe_not_set()}
      {406, _} -> {:ok, OriginSimulator.recipe_not_set(path)}
      _ -> {:ok, "Error #{status}"}
    end
  end

  defp cache_lookup(route) do
    case :ets.lookup(:payload, route) do
      [{^route, body}] -> {:ok, body}
      [] -> {:error, "content not found"}
    end
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    :ets.new(:payload, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, nil}
  end

  @impl true
  def handle_call({:fetch, origin, route}, _from, state) do
    {:ok, %HTTPoison.Response{body: body}} = @http_client.get(origin)
    :ets.insert(:payload, {route, body})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:parse, recipe, route}, _from, state) do
    :ets.insert(:payload, {route, Body.parse(recipe.body, recipe.headers)})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:generate, recipe, route}, _from, state) do
    :ets.insert(:payload, {route, Body.randomise(recipe.random_content, recipe.headers)})

    {:reply, :ok, state}
  end
end
