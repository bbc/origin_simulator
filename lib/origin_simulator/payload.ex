defmodule OriginSimulator.Payload do
  @moduledoc """
  Server for fetching payload from origin, storing and serving payloads.

  Recipe payload is pre-created and stored in memory 
  ([Erlang ETS](https://erlang.org/doc/man/ets.html)) when the 
  recipe is upload to OriginSimulator. This module provides API to
  fetch and store payload from origins specified in recipe so that 
  payload can be served repeatedly during simulation without hitting 
  the simulated origins. It also deals with body / random content payloads 
  if these are specified in recipe.
  """

  use GenServer
  alias OriginSimulator.{Body, Recipe}

  @http_client Application.get_env(:origin_simulator, :http_client)

  @type server :: pid() | :atom
  @type recipe :: OriginSimulator.Recipe.t()

  ## Client API

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  @doc """
  Fetch (from origin) or generate payload specified in recipe for in-memory storage.
  """
  @spec fetch(server, recipe) :: :ok
  def fetch(server, %Recipe{origin: value, route: route} = recipe) when is_binary(value) do
    GenServer.call(server, {:fetch, recipe, route})
  end

  def fetch(server, %Recipe{body: value, route: route} = recipe) when is_binary(value) do
    GenServer.call(server, {:parse, recipe, route})
  end

  def fetch(server, %Recipe{random_content: value, route: route} = recipe)
      when is_binary(value) do
    GenServer.call(server, {:generate, recipe, route})
  end

  @doc """
  Retrieve a payload from server for a given path and matching route.
  """
  @spec body(server, integer(), binary(), binary()) :: {:ok, term()} | {:error, binary()}
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
  def handle_call({:generate, recipe, route}, _from, state) do
    :ets.insert(:payload, {route, Body.randomise(recipe.random_content, recipe.headers)})

    {:reply, :ok, state}
  end
end
