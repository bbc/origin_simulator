defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Body, RecipeRoute}

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def update_payloads(server, recipe) do
    GenServer.call(server, {:update_payloads, recipe})
  end

  def body(server, status, pattern) do
    table = GenServer.call(server, :state)
    case status do
      200 -> cache_lookup(table, pattern)
      404 -> {:ok, "Not found"}
      _   -> {:ok, "Error #{status}"}
    end
  end

  def stop(server) do
    GenServer.stop(server)
  end

  defp cache_lookup(table, pattern) do
    case :ets.lookup(table, pattern) do
      [{_, body}] -> {:ok, body}
      [] -> {:error, "Could not find the payload in the cache"}
    end
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    {:ok, :ets.new(:payloads, [:set, :protected, read_concurrency: true])}
  end

  @impl true
  def handle_call({:update_payloads, recipe}, _from, state) do
    Enum.each(recipe, fn route -> cache_payload(state, route) end)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def terminate(_reason, state) do
    :ets.delete(state)
  end

  defp cache_payload(table, %RecipeRoute{origin: origin, pattern: pattern}) when is_binary(origin) do
    http_client = Application.get_env(:origin_simulator, :http_client)

    {:ok, %HTTPoison.Response{body: body}} = http_client.get(origin)
    :ets.insert(table, {pattern, body})
  end

  defp cache_payload(table, %RecipeRoute{body: body, pattern: pattern}) when is_binary(body) do
    :ets.insert(table, {pattern, Body.parse(body)})
  end

  defp cache_payload(table, %RecipeRoute{random_content: size, pattern: pattern}) when is_binary(size) do
    :ets.insert(table, {pattern, Body.randomise(size) })
  end
end
