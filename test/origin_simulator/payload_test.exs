defmodule OriginSimulator.PayloadTest do
  use ExUnit.Case, async: true

  alias OriginSimulator.Recipe

  @id :default

  describe "with origin" do
    setup do
      OriginSimulator.Payload.fetch(:payload, %Recipe{origin: "https://www.bbc.co.uk"})
    end

    test "Always return an error body for 5xx" do
      assert OriginSimulator.Payload.body(:payload, {@id, 500}) == {:ok, "Error 500"}
    end

    test "Always return 'Not Found' for 404s" do
      assert OriginSimulator.Payload.body(:payload, {@id, 404}) == {:ok, "Not found"}
    end

    test "Suggests to add a recipe for 406" do
      assert OriginSimulator.Payload.body(:payload, {@id, 406}) == {:ok, "Recipe not set, please POST a recipe to /add_recipe"}
    end

    test "returns the origin body for 200" do
      assert OriginSimulator.Payload.body(:payload, {@id, 200}) == {:ok, "some content from origin"}
    end
  end

  describe "with content" do
    setup do
      OriginSimulator.Payload.fetch(:payload, %Recipe{body: "{\"hello\":\"world\"}"})
    end

    test "Always return an error body for 5xx" do
      assert OriginSimulator.Payload.body(:payload, {@id, 500}) == {:ok, "Error 500"}
    end

    test "Always return 'Not Found' for 404s" do
      assert OriginSimulator.Payload.body(:payload, {@id, 404}) == {:ok, "Not found"}
    end

    test "Suggests to add a recipe for 406" do
      assert OriginSimulator.Payload.body(:payload, {@id, 406}) == {:ok, "Recipe not set, please POST a recipe to /add_recipe"}
    end

    test "returns the origin body for 200" do
      assert OriginSimulator.Payload.body(:payload, {@id, 200}) == {:ok, "{\"hello\":\"world\"}"}
    end
  end
end
