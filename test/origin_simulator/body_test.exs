defmodule OriginSimulator.RandomiserTest do
  use ExUnit.Case

  alias OriginSimulator.Body

  describe "parsing a string containg placeholders" do
    test "keeps text outside of placeholders " do
      parsed_string = Body.parse("abc{{4b}}def{{8b}}ghi")
      assert parsed_string =~ "abc"
    end

    test "replaces placeholders with random content " do
      parsed_string = Body.parse("abc{{4b}}def{{8b}}ghi")
      refute parsed_string =~ ~r"{{.+?}}"
    end
  end

  describe "parsing a string with no placeholders" do
    test "returns the same string content " do
      string = "abcdefghi"
      assert Body.parse(string) == string
    end
  end
end
