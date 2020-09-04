defmodule OriginSimulator.RateCalculator do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def rate() do
    GenServer.call(__MODULE__, :rate)
  end

  ## Server Callbacks

  @impl true
  def init(_), do: {:ok, 0}

  @impl true
  def handle_call(:rate, _from, rate), do: {:reply, rate, rate}
end
