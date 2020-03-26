defmodule OriginSimulator.Body do
  @regex ~r"<<(.+?)>>"

  alias OriginSimulator.Size

  def parse(str, headers \\ %{})

  def parse(str, %{"content-encoding" => "gzip"}) do
    Regex.replace(@regex, str, fn _whole, tag -> randomise(tag) end)
    |> :zlib.gzip()
  end

  def parse(str, _) do
    Regex.replace(@regex, str, fn _whole, tag -> randomise(tag) end)
  end

  def randomise(tag, headers \\ %{})
  def randomise(tag, %{"content-encoding" => "gzip"}), do: randomise(tag, %{}) |> :zlib.gzip()

  def randomise(tag, _) do
    size_in_bytes = Size.parse(tag)

    :crypto.strong_rand_bytes(size_in_bytes)
    |> Base.encode64()
    |> binary_part(0, size_in_bytes)
  end
end
