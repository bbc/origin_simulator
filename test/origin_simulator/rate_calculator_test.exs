defmodule OriginSimulator.RateCalculatorTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.{Counter, RateCalculator}

  @test_counter TestCounterForRateCalculator

  setup_all do
    {:ok, _} = start_supervised({Counter, name: TestCounterForRateCalculator})
    :ok
  end

  setup do
    Counter.clear(@test_counter)
  end

  test "rate() returns a valid integer request per-second rate" do
    assert RateCalculator.rate() |> is_integer()
  end

  test "state() returns the calculator state" do
    assert RateCalculator.state() == %{current_count: 0, rate: 0}
  end

  test "current_count/1 returns the current request count" do
    Counter.increment(200, @test_counter)
    Counter.increment(200, @test_counter)
    assert RateCalculator.current_count(@test_counter) == 2
  end

  test "handles request rate calculation" do
    current_calculator_state = %{rate: 0, current_count: 0}

    for _request <- 1..10 do
      Counter.increment(200, @test_counter)
    end

    {:noreply, new_calculator_state} = RateCalculator.handle_info({:calculate, @test_counter}, current_calculator_state)
    assert new_calculator_state.rate == 10
  end
end
