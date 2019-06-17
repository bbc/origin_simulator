defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Recipe, Size}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  def fetch(server, recipe = %Recipe{origin: origin}) when is_binary(origin) do
    GenServer.call(server, {:fetch, recipe})
  end

  def fetch(server, recipe = %Recipe{body: body}) when is_binary(body) do
    GenServer.call(server, {:parse, recipe})
  end

  def fetch(server, recipe = %Recipe{random_content: value}) when is_binary(value) do
    GenServer.call(server, {:generate, recipe})
  end

  def body(_server, {id, status}) do
    case status do
      200 -> cache_lookup(id)
      404 -> {:ok, "Not found"}
      406 -> {:ok, "Recipe not set, please POST a recipe to /add_recipe"}
      _   -> {:ok, "Error #{status}"}
    end
  end

  defp cache_lookup(id) do
    case :ets.lookup(:payload, id) do
      [{^id, body}] -> {:ok, body}
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
  def handle_call({:fetch, recipe}, _from, state) do
    env = Application.get_env(:origin_simulator, :env)

    {:ok, %HTTPoison.Response{body: body}} = OriginSimulator.HTTPClient.get(recipe.origin, env)
    :ets.insert(:payload, {recipe.id, body})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:parse, recipe}, _from, state) do
    :ets.insert(:payload, {recipe.id, recipe.body})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:generate, recipe}, _from, state) do
    size_in_bytes = Size.parse(recipe.random_content)

    body = :crypto.strong_rand_bytes(size_in_bytes)
    |> Base.encode64
    |> binary_part(0, size_in_bytes)

    :ets.insert(:payload, {recipe.id, body })

    {:reply, :ok, state}
  end
end
