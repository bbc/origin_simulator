defmodule OriginSimulator.Recipe do
  defstruct route: '/', origin: nil, body: nil, random_content: nil, stages: []
  @type t :: %__MODULE__{route: String.t(), origin: String.t(), body: String.t(), random_content: String.t()}
end
