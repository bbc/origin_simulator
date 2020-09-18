defmodule OriginSimulator.Counter do
  @moduledoc false

  use Agent

  @initial_state %{total_requests: 0}

  def start_link(_opts) do
    Agent.start_link(fn -> @initial_state end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def clear do
    Agent.update(__MODULE__, fn _state ->
      @initial_state
    end)
  end

  def increment(status_code) do
    Agent.update(__MODULE__, fn state ->
      state
      |> increment_key(:total_requests)
      |> increment_key(status_code)
    end)
  end

  defp increment_key(state, key) do
    {_, state} =
      Map.get_and_update(state, key, fn
        nil -> {nil, 1}
        current_value -> {current_value, current_value + 1}
      end)

    state
  end
end
