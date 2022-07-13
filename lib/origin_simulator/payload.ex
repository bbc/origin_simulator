defmodule OriginSimulator.Payload do
  use GenServer

  alias OriginSimulator.{Body, Recipe}

  @http_client Application.get_env(:origin_simulator, :http_client)

  @random_payload_step_size 5
  @unit "kb"
  @unit_regex ~r/kb/

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  # TODO: rename `fetch` to `create` or `generate` to better reflect that OS actually create
  # in-memory payload via various mechanisms, i.e. fetch from origin,
  # provided in recipe or random content
  def fetch(server, %Recipe{origin: value, route: route} = recipe) when is_binary(value) do
    GenServer.call(server, {:fetch, recipe, route})
  end

  def fetch(server, %Recipe{body: value, route: route} = recipe) when is_binary(value) do
    GenServer.call(server, {:parse, recipe, route})
  end

  def fetch(server, %Recipe{random_content: value, route: route} = recipe) when is_binary(value) do
    case String.contains?(value, "..") do
      true -> fetch(server, %{recipe | random_content: String.split(value, "..")})
      false -> GenServer.call(server, {:generate, recipe, route})
    end
  end

  def fetch(server, %Recipe{random_content: [_min, _max], route: route} = recipe) do
    GenServer.call(server, {:generate, recipe, route})
  end

  def body(_server, status, path \\ Recipe.default_route(), route \\ Recipe.default_route()) do
    case {status, path} do
      {200, _} -> cache_lookup(route)
      {304, _} -> {:ok, ""}
      {404, _} -> {:ok, "Not found"}
      {406, "/*"} -> {:ok, OriginSimulator.recipe_not_set()}
      {406, _} -> {:ok, OriginSimulator.recipe_not_set(path)}
      _ -> {:ok, "Error #{status}"}
    end
  end

  def random_payload_step_size, do: @random_payload_step_size

  def random_payload_series([min, max]) do
    min_integer = Regex.replace(@unit_regex, min, "") |> String.to_integer()
    max_integer = Regex.replace(@unit_regex, max, "") |> String.to_integer()

    min_integer..max_integer
    |> Enum.take_every(@random_payload_step_size)
    |> Enum.filter(&(&1 != 0))
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
  def handle_call({:fetch, recipe, route}, _from, state) do
    {:ok, %HTTPoison.Response{body: body}} = @http_client.get(recipe.origin, recipe.headers)
    :ets.insert(:payload, {route, body})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:parse, recipe, route}, _from, state) do
    :ets.insert(:payload, {route, Body.parse(recipe.body, recipe.headers)})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:generate, %{random_content: [min, max]} = recipe, route}, _from, state) do
    :ets.insert(:payload, {route, Body.randomise(max, recipe.headers)})

    random_payload_series([min, max])
    |> Enum.each(fn size ->
      size_kb = Integer.to_string(size) <> @unit
      :ets.insert(:payload, {{route, size}, Body.randomise(size_kb, recipe.headers)})
    end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:generate, recipe, route}, _from, state) do
    :ets.insert(:payload, {route, Body.randomise(recipe.random_content, recipe.headers)})

    {:reply, :ok, state}
  end
end
