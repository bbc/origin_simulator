defmodule OriginSimulator.RateCalculatorTest do
  use ExUnit.Case

  alias OriginSimulator.RateCalculator

  test "state() returns a valid integer request per-second rate" do
    assert RateCalculator.rate() |> is_integer()
  end
end
