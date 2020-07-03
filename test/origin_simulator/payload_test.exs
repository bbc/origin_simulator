defmodule OriginSimulator.PayloadTest do
  use ExUnit.Case, async: true
  import Fixtures.Recipes
  import OriginSimulator, only: [recipe_not_set: 0]

  alias OriginSimulator.Payload

  # TODO: additional tests for fetching and storing multi-origin / source content in ETS
  describe "with origin" do
    setup do
      Payload.fetch(:payload, origin_recipe())
    end

    test "Always returns payload body for 5xx" do
      assert Payload.body(:payload, 500) == {:ok, "some content from origin"}
    end

    test "Always returns payload body for 404s" do
      assert Payload.body(:payload, 404) == {:ok, "some content from origin"}
    end

    test "Suggests to add a recipe for 406" do
      assert Payload.body(:payload, 406) == {:ok, recipe_not_set()}
    end

    test "returns the origin body for 200" do
      assert Payload.body(:payload, 200) == {:ok, "some content from origin"}
    end
  end

  describe "with content" do
    setup do
      Payload.fetch(:payload, body_recipe())
    end

    test "Always returns payload body for 5xx" do
      assert Payload.body(:payload, 500) == {:ok, ~s({"hello":"world"})}
    end

    test "Always returns payload body for 404s" do
      assert Payload.body(:payload, 404) == {:ok, ~s({"hello":"world"})}
    end

    test "Suggests to add a recipe for 406" do
      assert Payload.body(:payload, 406) == {:ok, recipe_not_set()}
    end

    test "returns the origin body for 200" do
      assert Payload.body(:payload, 200) == {:ok, "{\"hello\":\"world\"}"}
    end
  end

  describe "recipe with gzip content-encoding header" do
    test "returns gzip body from origin" do
      Payload.fetch(:payload, origin_recipe(%{"content-encoding" => "gzip"}))
      assert Payload.body(:payload, 200) == {:ok, :zlib.gzip("some content from origin")}
    end

    test "returns gzip body (posted)" do
      Payload.fetch(:payload, body_recipe(%{"content-encoding" => "gzip"}))
      assert Payload.body(:payload, 200) == {:ok, :zlib.gzip("{\"hello\":\"world\"}")}
    end

    test "returns gzip random content" do
      Payload.fetch(:payload, random_content_recipe("10kb", %{"content-encoding" => "gzip"}))
      {:ok, gzip_content} = Payload.body(:payload, 200)

      assert gzip_content |> :zlib.gunzip() |> String.length() == 10 * 1024
    end
  end
end
