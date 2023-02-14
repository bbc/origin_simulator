defmodule OriginSimulator.Recipe do
  defstruct origin: nil, body: nil, random_content: nil, headers: %{}, stages: [], route: "/*"

  @type t :: %__MODULE__{
          origin: String.t(),
          body: String.t(),
          random_content: String.t(),
          headers: map(),
          route: String.t()
        }

  # TODO: parameters don't make sense, need fixing
  @spec parse({:ok, binary(), any()}) :: binary()
  def parse({:ok, "[" <> body, _conn}), do: Poison.decode!("[" <> body, as: [%__MODULE__{}])
  def parse({:ok, body, _conn}), do: Poison.decode!(body, as: %__MODULE__{})
  def parse(body), do: Poison.decode!(body, as: %__MODULE__{})

  @spec default_route() :: binary()
  def default_route(), do: %__MODULE__{}.route
end
