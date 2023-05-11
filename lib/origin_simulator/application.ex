defmodule OriginSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Bandit,
       plug: OriginSimulator,
       scheme: :http,
       thousand_island_options: [
         shutdown_timeout: 10_000,
         read_timeout: 45_000,
         num_acceptors: 100,
         num_connections: 16_384
       ]},
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
