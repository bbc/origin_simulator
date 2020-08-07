defmodule OriginSimulator.Flakiness do
  @moduledoc """
  A server that introduces latency, payload and status flakiness
  during simulation.
  """
  use GenServer
  alias OriginSimulator.{Flakiness, Payload}

  @default_interval 1000
  @simulation_server :simulation

  defstruct payload: [], status: [], route: "/*", interval: nil

  @type t :: %__MODULE__{
          payload: [binary()],
          status: [integer()],
          route: binary,
          interval: integer()
        }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :flakiness)
  end

  def new(), do: %Flakiness{}
  def new(payload_series, route), do: %Flakiness{payload: payload_series, route: route}

  def start(%{random_content: value}, route) do
    String.split(value, "..")
    |> Payload.random_payload_series()
    |> Flakiness.new(route)
    |> Map.put(:interval, @default_interval)
    |> set()

    start()
  end

  def set(flakiness), do: GenServer.call(:flakiness, {:set, flakiness})
  def state(), do: GenServer.call(:flakiness, :state)
  def start(), do: GenServer.call(:flakiness, :start)

  # TODO
  # def stop()

  # Callbacks 

  @impl true
  def init(_) do
    {:ok, new()}
  end

  @impl true
  def handle_call(:state, _from, flakiness) do
    {:reply, flakiness, flakiness}
  end

  @impl true
  def handle_call(:start, _from, flakiness) do
    send(self(), :flaky)
    {:reply, :ok, flakiness}
  end

  @impl true
  def handle_call({:set, new_flakiness}, _from, _flakiness) do
    {:reply, :ok, new_flakiness}
  end

  @impl true
  def handle_info(:flaky, flakiness) do
    send(
      @simulation_server,
      {:update, {flakiness.route, flakiness.payload |> Enum.random()}}
    )

    {:noreply, flakiness}
  end
end
