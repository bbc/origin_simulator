defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.Recipe
  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  def fetch(server, %Recipe{origin: value}) when is_binary(value) do
    GenServer.call(server, {:fetch, value})
  end

  def fetch(server, %Recipe{random: value}) when is_number(value) do
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
  def handle_call({:generate, size}, _from, state) do
    size = size * 1024
    body = :crypto.strong_rand_bytes(size) |> Base.encode64 |> binary_part(0, size)
    :ets.insert(:payload, {"body", body })

    {:reply, :ok, state}
  end
end
