defmodule OriginSimulator.RandomiserTest do
  use ExUnit.Case

  alias OriginSimulator.Body

  describe "parsing a string containg a placeholder" do
    test "keeps text outside of placeholders " do
      decoded_body = Body.parse("{\"data\":\"<<1kb>>\"}") |> Poison.decode!()
      assert String.length(decoded_body["data"]) == 1024
    end

    test "replaces placeholders with random content" do
      parsed_string = Body.parse("{\"data\":\"some random<<4kb>>and also<<10kb>>this\"}")
      refute parsed_string =~ ~r"<<.+?>>"
    end
  end

  describe "parsing a string containg multiple placeholders" do
    test "keeps text outside of placeholders " do
      parsed_string = Body.parse("{\"data\":\"some random<<4kb>>and also<<10kb>>this\"}")
      assert parsed_string =~ "some random"
    end

    test "replaces placeholders with random content " do
      parsed_string = Body.parse("{\"data\":\"some random<<4kb>>and also<<10kb>>this\"}")
      refute parsed_string =~ ~r"<<.+?>>"
    end
  end

  describe "parsing a string with no placeholders" do
    test "returns the same string content " do
      string = "abcdefghi"
      assert Body.parse(string) == string
    end
  end
end
