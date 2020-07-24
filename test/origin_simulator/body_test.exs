defmodule OriginSimulator.RandomiserTest do
  use ExUnit.Case

  alias OriginSimulator.Body

  describe "parsing a string containg a placeholder" do
    test "keeps text outside of placeholders " do
      decoded_body = Body.parse("{\"data\":\"<<1kb>>\"}") |> Poison.decode!()
      assert String.length(decoded_body["data"]) == 1024
    end

    test "keeps text (gzip) outside of placeholders " do
      headers = %{"content-encoding" => "gzip"}

      decoded_body =
        Body.parse("{\"data\":\"<<1kb>>\"}", headers)
        |> :zlib.gunzip()
        |> Poison.decode!()

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

    test "keeps text (gzip) outside of placeholders " do
      headers = %{"content-encoding" => "gzip"}

      parsed_string =
        Body.parse("{\"data\":\"some random<<4kb>>and also<<10kb>>this\"}", headers)
        |> :zlib.gunzip()

      assert parsed_string =~ "some random"
    end

    test "replaces placeholders with random content" do
      parsed_string = Body.parse("{\"data\":\"some random<<4kb>>and also<<10kb>>this\"}")
      refute parsed_string =~ ~r"<<.+?>>"
    end

    test "produces a random string of the expected size" do
      decoded_body = Body.parse("{\"data\":\"some random<<4kb>>and also<<10kb>>this\"}") |> Poison.decode!()

      assert String.length(decoded_body["data"]) == 14_359
    end
  end

  describe "parsing a string with no placeholders" do
    test "returns the same string content " do
      string = "abcdefghi"
      assert Body.parse(string) == string
    end

    test "returns gzip string" do
      string = "abcdefghi"
      headers = %{"content-encoding" => "gzip"}
      assert Body.parse(string, headers) == :zlib.gzip(string)
    end
  end

  describe "generating random content" do
    test "returns content of expected size" do
      assert Body.randomise("300kb") |> String.length() == 300 * 1024
    end

    test "returns gzip content of expected size" do
      headers = %{"content-encoding" => "gzip"}
      assert Body.randomise("300kb", headers) |> :zlib.gunzip() |> String.length() == 300 * 1024
    end
  end
end
