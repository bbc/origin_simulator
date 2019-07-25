defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Body, Recipe}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payloads)
  end

  def update_recipe_book(server, recipe_book) do
    GenServer.call(server, {:update_recipe_book, recipe_book})
  end

  def body(_server, status, route) do
    case status do
      200 -> cache_lookup(route)
      404 -> {:ok, "Not found"}
      406 -> {:ok, "Recipe not set, please POST a recipe to /add_recipe"}
      _   -> {:ok, "Error #{status}"}
    end
  end

  def restart do
    GenServer.stop(:payloads)
  end

  defp cache_lookup(route) do
    case :ets.lookup(:payloads, route) do
      [{^route, body}] -> {:ok, body}
      [] -> {:error, "content not found"}
    end
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    :ets.new(:payloads, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, nil}
  end

  @impl true
  def handle_call({:update_recipe_book, recipe_book}, _from, state) do
    Enum.each(recipe_book, &cache_payload/1)

    {:reply, :ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ets.delete(:payloads)
  end

  defp cache_payload(%Recipe{origin: origin, route: route}) when is_binary(origin) do
    env = Application.get_env(:origin_simulator, :env)

    {:ok, %HTTPoison.Response{body: body}} = OriginSimulator.HTTPClient.get(origin, env)
    :ets.insert(:payloads, {route, body})
  end

  defp cache_payload(%Recipe{body: body, route: route}) when is_binary(body) do
    :ets.insert(:payloads, {route, Body.parse(body)})
  end

  defp cache_payload(%Recipe{random_content: size, route: route}) when is_binary(size) do
    :ets.insert(:payloads, {route, Body.randomise(size) })
  end
end
