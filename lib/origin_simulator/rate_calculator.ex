defmodule OriginSimulator.RateCalculator do
  use GenServer

  alias OriginSimulator.Counter

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: if(name, do: name, else: __MODULE__))
  end

  def rate(calculator \\ __MODULE__), do: GenServer.call(calculator, :rate)
  def state(calculator \\ __MODULE__), do: GenServer.call(calculator, :state)

  def current_count(counter \\ Counter), do: Counter.value(counter).total_requests

  ## Server Callbacks

  @impl true
  def init(opts) do
    counter = Keyword.get(opts, :counter)
    send(self(), {:calculate, if(counter, do: counter, else: Counter)})

    {:ok, %{rate: 0, current_count: 0}}
  end

  @impl true
  def handle_call(:rate, _from, state), do: {:reply, state.rate, state}

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info({:calculate, counter}, state) do
    Process.send_after(self(), {:calculate, counter}, 1000)

    new_count = current_count(counter)
    {:noreply, %{rate: new_count - state.current_count, current_count: new_count}}
  end
end
