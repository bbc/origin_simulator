defmodule OriginSimulator.RecipeRoute do
  defstruct pattern: "/*", origin: nil, body: nil, random_content: nil, stages: []
  @type t :: %__MODULE__{pattern: String.t(), origin: String.t(), body: String.t(), random_content: String.t()}
end
