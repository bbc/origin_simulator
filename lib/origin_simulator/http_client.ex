defmodule OriginSimulator.HTTPClient do
  def get(endpoint) do
    headers = []
    options = [recv_timeout: 3000]

    HTTPoison.get(endpoint, headers, options)
  end
end
