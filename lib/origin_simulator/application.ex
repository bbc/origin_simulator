defmodule OriginSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: OriginSimulator,
        options: [
          port: Application.fetch_env!(:origin_simulator, :http_port),
          protocol_options: [max_keepalive: 5_000_000]
        ]
      ),
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
