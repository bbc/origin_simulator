defmodule OriginSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: OriginSimulator,
        options: [port: 8080, protocol_options: [max_keepalive: 5_000_000]]
      ),
      OriginSimulator.Simulation,
      OriginSimulator.Payload
      #:hackney_pool.child_spec(:origin_pool, [timeout: 10_000, max_connections: 8000]),
    ]

    opts = [strategy: :one_for_one, name: OriginSimulator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
