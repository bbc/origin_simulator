defmodule OriginSimulator.PayloadTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.Recipe

  # TODO: additional tests for fetching and storing multi-origin / source content in ETS
  describe "with origin" do
    setup do
      OriginSimulator.Payload.fetch(:payload, %Recipe{origin: "https://www.bbc.co.uk"})
    end

    test "Always return an error body for 5xx" do
      assert OriginSimulator.Payload.body(:payload, 500) == {:ok, "Error 500"}
    end

    test "Always return 'Not Found' for 404s" do
      assert OriginSimulator.Payload.body(:payload, 404) == {:ok, "Not found"}
    end

    test "Suggests to add a recipe for 406" do
      assert OriginSimulator.Payload.body(:payload, 406) == {:ok, "Recipe not set, please POST a recipe to /#{OriginSimulator.admin_domain()}/add_recipe"}
    end

    test "returns the origin body for 200" do
      assert OriginSimulator.Payload.body(:payload, 200) == {:ok, "some content from origin"}
    end
  end

  describe "with content" do
    setup do
      OriginSimulator.Payload.fetch(:payload, %Recipe{body: "{\"hello\":\"world\"}"})
    end

    test "Always return an error body for 5xx" do
      assert OriginSimulator.Payload.body(:payload, 500) == {:ok, "Error 500"}
    end

    test "Always return 'Not Found' for 404s" do
      assert OriginSimulator.Payload.body(:payload, 404) == {:ok, "Not found"}
    end

    test "Suggests to add a recipe for 406" do
      assert OriginSimulator.Payload.body(:payload, 406) == {:ok, "Recipe not set, please POST a recipe to /#{OriginSimulator.admin_domain()}/add_recipe"}
    end

    test "returns the origin body for 200" do
      assert OriginSimulator.Payload.body(:payload, 200) == {:ok, "{\"hello\":\"world\"}"}
    end
  end

  describe "gzip response" do
    test "returns the origin body for 200" do
      recipe = %Recipe{origin: "https://www.bbc.co.uk", headers: %{"content-encoding" => "gzip"}}
      OriginSimulator.Payload.fetch(:payload, recipe)

      assert OriginSimulator.Payload.body(:payload, 200) == {:ok, :zlib.gzip("some content from origin")}
    end
  end
end
