defmodule OriginSimulator.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      OriginSimulator.Payload,
      OriginSimulator.Counter,
      OriginSimulator.Simulation
    ]

    opts = [
      strategy: :one_for_all,
      max_restarts: 30
    ]

    Supervisor.init(children, opts)
  end
end
