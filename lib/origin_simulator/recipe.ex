defmodule OriginSimulator.Recipe do
  @moduledoc """
  Data struct and functions underpinning OriginSimulator recipes.

  A recipe defines the different stages of a [simulation scenario](readme.html#scenarios).
  It is a JSON that can be uploaded to OriginSimulator via HTTP POST. The recipe is
  represented internally as a struct. This module also provides a function to parse
  JSON recipe into struct.
  """

  defstruct origin: nil, body: nil, random_content: nil, headers: %{}, stages: [], route: "/*"

  @type t :: %__MODULE__{
          origin: String.t(),
          body: String.t(),
          random_content: String.t(),
          headers: map(),
          route: String.t()
        }

  @doc """
  Parse a JSON recipe into `t:OriginSimulator.Recipe.t/0` data struct.
  """
  # TODO: parameters don't make sense, need fixing
  @spec parse({:ok, binary(), any()}) :: binary()
  def parse({:ok, "[" <> body, _conn}), do: Poison.decode!("[" <> body, as: [%__MODULE__{}])
  def parse({:ok, body, _conn}), do: Poison.decode!(body, as: %__MODULE__{})

  @doc false
  @spec default_route() :: binary()
  def default_route(), do: %__MODULE__{}.route
end
