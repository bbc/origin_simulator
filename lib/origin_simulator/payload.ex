defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Body, Recipe, Size}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  def fetch(server, %Recipe{origin: value}) when is_binary(value) do
    GenServer.call(server, {:fetch, value})
  end

  def fetch(server, %Recipe{body: value}) when is_binary(value) do
    GenServer.call(server, {:parse, value})
  end

  def fetch(server, %Recipe{random_content: value}) when is_binary(value) do
    GenServer.call(server, {:generate, value})
  end

  def body(_server, status) do
    case status do
      200 -> cache_lookup()
      404 -> {:ok, "Not found"}
      406 -> {:ok, "Recipe not set, please POST a recipe to /add_recipe"}
      _   -> {:ok, "Error #{status}"}
    end
  end

  defp cache_lookup() do
    case :ets.lookup(:payload, "body") do
      [{"body", body}] -> {:ok, body}
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
  def handle_call({:fetch, origin}, _from, state) do
    env = Application.get_env(:origin_simulator, :env)

    {:ok, %HTTPoison.Response{body: body}} = OriginSimulator.HTTPClient.get(origin, env)
    :ets.insert(:payload, {"body", body})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:parse, body}, _from, state) do
    :ets.insert(:payload, {"body", Body.parse(body)})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:generate, size}, _from, state) do
    :ets.insert(:payload, {"body", Body.randomise(size) })

    {:reply, :ok, state}
  end
end
