defmodule OriginSimulator.Body do
  @regex ~r"{{(.+?)}}"

  alias OriginSimulator.Size

  def parse(str) do
    Regex.replace(@regex, str, fn _whole, tag -> randomise(tag) end)
  end

  def randomise(tag) do
    size_in_bytes = Size.parse(tag)

    :crypto.strong_rand_bytes(size_in_bytes)
    |> Base.encode64
    |> binary_part(0, size_in_bytes)
  end
end
