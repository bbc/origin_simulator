defmodule OriginSimulator.HTTPClient do
  def get(endpoint, headers \\ %{})  
  
  def get(endpoint, %{"content-encoding" => "gzip"} = headers) do
    new_headers = headers
    |> Map.delete("content-encoding")
    |> Map.put("accept-encoding", "gzip")

    get(endpoint, new_headers)
  end

  def get(endpoint, headers) do
    options = [recv_timeout: 3000]
    HTTPoison.get(endpoint, headers |> Map.to_list, options)
  end
end
