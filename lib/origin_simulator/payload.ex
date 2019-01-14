defmodule OriginSimulator.Payload do
  use GenServer

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :payload)
  end

  def fetch(server, origin) do
    GenServer.cast(server, {:fetch, origin})
  end

  def body(server, status) do
    case status do
      200 -> GenServer.call(server, :body)
      404 -> "Not found"
      406 -> "Recipe not set, please POST a recipe to /add_recipe"
      _   -> "Error #{status}"
    end
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:fetch, origin}, _state) do
    {:ok, response} = http_client().get(origin)
    {:noreply, response}
  end

  @impl true
  def handle_call(:body, _from, state) do
    {:reply, state.body, state}
  end

  defp http_client() do
    Application.get_env(:origin_simulator, :http_client)
  end
end
