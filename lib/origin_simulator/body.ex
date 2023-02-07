defmodule OriginSimulator.Body do
  @moduledoc """
  Utilities for generating OriginSimulator recipe response payloads (body).
  """
  @regex ~r"<<(.+?)>>"

  alias OriginSimulator.Size

  @doc """
  Parse a string value to include generated and compressed random payload if required.

  OriginSimulator response payload can be defined in recipes. The payload
  can also include random content specified with tags, e.g. <<10kb>>.

  ```
  iex> OriginSimulator.Body.parse("{\"payload\":\"test\"}")
  "{\"payload\":\"test\"}"

  # generate random content with <<100b>>
  iex> OriginSimulator.Body.parse("{\"payload\":\"<<100b>>\"}")
  "{\"payload\":\"iDS0MMNKT3QMmEiOPvjeIsEXB7cjGlGktCLCMta3D8ZleSHbcbUn1mNa470POxzDJAhJvP4L3cDhDvwBP5eQC8fGMo3DCgewZzBv\"}"
  ```

  Payload can be compressed with a `%{"content-encoding" => "gzip"}` header.
  ```
  iex> OriginSimulator.Body.parse("{\"payload\":\"<<100b>>\"}", %{"content-encoding" => "gzip"})
  <<31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 171, 86, 42, 72, 172, 204, 201, 79, 76, 81,
    178, 82, 50, 8, 115, 214, 15, 169, 114, 245, 74, 244, 204, 205, 44, 54, 52,
    174, 242, 170, 204, 244, 11, 171, 172, 50, 205, 201, 43, 54, ...>>
  ```
  """
  @spec parse(binary(), map()) :: binary()
  def parse(str, headers \\ %{})

  def parse(str, %{"content-encoding" => "gzip"}) do
    Regex.replace(@regex, str, fn _whole, tag -> randomise(tag) end)
    |> :zlib.gzip()
  end

  def parse(str, _) do
    Regex.replace(@regex, str, fn _whole, tag -> randomise(tag) end)
  end

  @doc """
  Generate and compress random payload.

  ```
  # generate 100kb random payload in gzip format
  iex(1)> OriginSimulator.Body.randomise("100kb", %{"content-encoding" => "gzip"})
  <<31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 20, 154, 69, 178, 227, 64, 16, 5, 15, 228,
    133, 152, 150, 98, 102, 214, 78, 204, 204, 58, 253, 252, 89, 59, 28, 182, 186,
    171, 222, 203, 116, 88, 158, 88, 201, 207, 21, 14, 52, 48, ...>>
  ```
  """
  @spec randomise(binary(), map()) :: binary()
  def randomise(tag, headers \\ %{})
  def randomise(tag, %{"content-encoding" => "gzip"}), do: randomise(tag, %{}) |> :zlib.gzip()

  def randomise(tag, _) do
    size_in_bytes = Size.parse(tag)

    :crypto.strong_rand_bytes(size_in_bytes)
    |> Base.encode64()
    |> binary_part(0, size_in_bytes)
  end
end
