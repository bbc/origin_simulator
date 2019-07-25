defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Body, Recipe, Size}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payloads)
  end

  def fetch(server, %Recipe{origin: value, route: route}) when is_binary(value) do
    GenServer.call(server, {:fetch, route, value})
  end

  def fetch(server, %Recipe{body: value, route: route}) when is_binary(value) do
    GenServer.call(server, {:parse, route, value})
  end

  def fetch(server, %Recipe{random_content: value, route: route}) when is_binary(value) do
    GenServer.call(server, {:generate, route, value})
  end

  def body(_server, status, route) do
    case status do
      200 -> cache_lookup(route)
      404 -> {:ok, "Not found"}
      406 -> {:ok, "Recipe not set, please POST a recipe to /add_recipe"}
      _   -> {:ok, "Error #{status}"}
    end
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
  def handle_call({:fetch, route, origin}, _from, state) do
    env = Application.get_env(:origin_simulator, :env)

    {:ok, %HTTPoison.Response{body: body}} = OriginSimulator.HTTPClient.get(origin, env)
    :ets.insert(:payloads, {route, body})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:parse, route, body}, _from, state) do
    :ets.insert(:payloads, {route, Body.parse(body)})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:generate, route, size}, _from, state) do
    :ets.insert(:payloads, {route, Body.randomise(size) })

    {:reply, :ok, state}
  end
end
