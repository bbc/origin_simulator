defmodule OriginSimulator.DurationTest do
  use ExUnit.Case

  alias OriginSimulator.Duration

  describe "parsing a integer" do
    test "0" do
      assert Duration.parse(0) == nil
    end
  end

  describe "parsing a binary string" do
    test "0" do
      assert Duration.parse("0") == nil
    end

    test "0ms" do
      assert Duration.parse("0ms") == 0
    end

    test "0s" do
      assert Duration.parse("0s") == 0
    end

    test "100ms" do
      assert Duration.parse("100ms") == 100
    end

    test "1ms" do
      assert Duration.parse("1s") == 1000
    end

    test "range 100ms..200ms" do
      assert Duration.parse("100ms..200ms") == 100..200
    end

    test "range 1s..2s" do
      assert Duration.parse("1s..2s") == 1000..2000
    end

    test "range 800ms..1s" do
      assert Duration.parse("800ms..1s") == 800..1000
    end
  end

  describe "parsing a tuple" do
    test "0" do
      assert Duration.parse({0, ""}) == nil
    end

    test "0ms" do
      assert Duration.parse({0, "ms"}) == 0
    end

    test "0s" do
      assert Duration.parse({0, "s"}) == 0
    end

    test "100ms" do
      assert Duration.parse({100, "ms"}) == 100
    end

    test "1ms" do
      assert Duration.parse({1, "s"}) == 1000
    end
  end

  describe "parsing an array of tuples" do
    test "range 100ms..200ms" do
      assert Duration.parse([{100, "ms"}, {200, "ms"}]) == 100..200
    end

    test "range 1s..2s" do
      assert Duration.parse([{1, "s"}, {2, "s"}]) == 1000..2000
    end

    test "range 800ms..1s" do
      assert Duration.parse([{800, "ms"}, {1, "s"}]) == 800..1000
    end
  end
end
