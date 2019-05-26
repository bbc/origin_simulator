defmodule OriginSimulator.SizeTest do
  use ExUnit.Case

  alias OriginSimulator.Size

  describe "Success" do
    test "123b" do
      assert Size.parse("123b") == 123
    end

    test "123kb" do
      assert Size.parse("123kb") == 123 * 1024
    end

    test "123mb" do
      assert Size.parse("123mb") == 123 * 1024 * 1024
    end
  end

  describe "failure" do
    test "123" do
      assert_raise RuntimeError, "Invalid size, please define size in b, kb or mb", fn () -> Size.parse("123") end
    end

    test "123tb" do
      assert_raise RuntimeError, "Invalid size, please define size in b, kb or mb", fn () -> Size.parse("123tb") end
    end
  end
end
