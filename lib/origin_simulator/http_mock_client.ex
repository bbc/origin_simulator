defmodule OriginSimulator.HTTPMockClient do
  def get(_endpoint) do
    {:ok, %{ body: "some content from origin" }}
  end
end
