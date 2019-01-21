defmodule OriginSimulator.Recipe do

  @spec parse(%Plug.Conn{}) :: String.t()
  def parse(conn = %Plug.Conn{}) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    Poison.decode!(body)
  end
end
