defmodule OriginSimulator.CounterTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.Counter

  setup_all do
    {:ok, _} = start_supervised({Counter, name: TestCounter})
    :ok
  end

  setup do
    Counter.clear(TestCounter)
    :ok
  end

  test "clear/1 resets total requests to zero initial state" do
    assert Counter.value(TestCounter).total_requests == 0
  end

  test "value/1 returns the current count" do
    assert Counter.value(TestCounter).total_requests == 0
  end

  test "increment/1 adds to the current count" do
    Counter.increment(200, TestCounter)
    Counter.increment(200, TestCounter)
    assert Counter.value(TestCounter).total_requests == 2
  end

  test "increment/1 adds to the current count for the status" do
    Counter.increment(404, TestCounter)
    assert Counter.value(TestCounter)[404] == 1
  end
end
