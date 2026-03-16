defmodule OriginSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Bandit, plug: OriginSimulator},
      OriginSimulator.Supervisor
    ]

    opts = [
      strategy: :one_for_one,
      name: OriginSimulator.AppSupervisor,
      max_restarts: 30
    ]

    Supervisor.start_link(children, opts)
  end
end
