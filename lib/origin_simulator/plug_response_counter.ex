defmodule OriginSimulator.PlugResponseCounter do
  @behaviour Plug
  import Plug.Conn, only: [register_before_send: 2]

  def init(opts), do: opts

  def call(conn, _opts) do
    register_before_send(conn, fn conn ->
      OriginSimulator.Counter.increment(conn.status)
      conn
    end)
  end
end
