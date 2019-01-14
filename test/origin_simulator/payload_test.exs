defmodule OriginSimulator.PayloadTest do
  use ExUnit.Case, async: true

  setup do
    %{payload: :payload}

    OriginSimulator.Payload.fetch(:payload, "https://www.google.com")
  end

  test "Always return an error body for 5xx" do
    assert OriginSimulator.Payload.body(:payload, 500) == "Error 500"
  end

  test "Always return 'Not Found' for 404s" do
    assert OriginSimulator.Payload.body(:payload, 404) == "Not found"
  end

  test "Suggests to add a recipe for 406" do
    assert OriginSimulator.Payload.body(:payload, 406) == "Recipe not set, please POST a recipe to /add_recipe"
  end

  test "returns the origin body for 200" do
    assert OriginSimulator.Payload.body(:payload, 200) == "some content from origin"
  end
end
