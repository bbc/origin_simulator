defmodule OriginSimulator.Payload do
  use GenServer

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  def fetch(server, origin) do
    GenServer.cast(server, {:fetch, origin})
  end

  def generate(server, size) do
    GenServer.cast(server, {:generate, size})
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
      [] -> :error
    end
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    :ets.new(:payload, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, nil}
  end

  @impl true
  def handle_cast({:fetch, origin}, state) do
    {:ok, %HTTPoison.Response{body: body } } = OriginSimulator.HTTPClient.get(origin)
    :ets.insert(:payload, {"body", body })

    {:noreply, state}
  end

  @impl true
  def handle_cast({:generate, size}, state) do
    size = size * 1024
    body = :crypto.strong_rand_bytes(size) |> Base.encode64 |> binary_part(0, size)
    :ets.insert(:payload, {"body", body })

    {:noreply, state}
  end
end
