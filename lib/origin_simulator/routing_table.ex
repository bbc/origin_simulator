defmodule OriginSimulator.RoutingTable do
  use GenServer

  ## Client API
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def find_route(server, path) do
    GenServer.call(server, :routing_table)
    |> Enum.find(fn pattern -> String.match?(path, Regex.compile!(pattern)) end)
    |> case do
         nil     -> {:error, "The request path doesn't match any of the defined routes"}
         pattern -> {:ok, pattern}
       end
  end

  def update_routing_table(server, recipe) do
    GenServer.call(server, {:update_routing_table, recipe})
  end
  

  ## Server Callbacks
  
  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call(:routing_table, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:update_routing_table, recipe}, _from, state) do
    routing_table = Enum.map(recipe, fn route ->
      Regex.compile!(route.pattern)
      route.pattern
    end)
    {:reply, :ok, routing_table}
  rescue
    Regex.CompileError -> {:reply, :error, state} 
  end
end
