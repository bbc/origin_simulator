defmodule OriginSimulator.HTTP.MockClient do
  def get(_endpoint, headers \\ %{})
  def get(_endpoint, %{"content-type" => "application/json"}), do: {:ok, %HTTPoison.Response{body: "{\"hello\":\"world\"}"}}
  def get(_endpoint, %{"content-encoding" => "gzip"}), do: {:ok, %HTTPoison.Response{body: :zlib.gzip("some content from origin")}}
  def get(_endpoint, _headers), do: {:ok, %HTTPoison.Response{body: "some content from origin"}}
end
