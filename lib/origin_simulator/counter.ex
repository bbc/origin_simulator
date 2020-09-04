defmodule OriginSimulator.Counter do
  use Agent

  @initial_state %{total_requests: 0}

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    Agent.start_link(fn -> @initial_state end, name: if(name, do: name, else: __MODULE__))
  end

  def value(agent \\ __MODULE__) do
    Agent.get(agent, & &1)
  end

  def clear(agent \\ __MODULE__) do
    Agent.update(agent, fn _state ->
      @initial_state
    end)
  end

  def increment(status_code, agent \\ __MODULE__) do
    Agent.update(agent, fn state ->
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
