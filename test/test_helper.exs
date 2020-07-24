Code.require_file("fixtures/fixtures.exs", __DIR__)
Code.require_file("fixtures/recipes.exs", __DIR__)

ExUnit.start()

defmodule TestHelpers do
  use Plug.Test
  import ExUnit.Assertions

  def admin_domain(), do: OriginSimulator.admin_domain()

  def assert_status_body(conn, status, body) do
    assert conn.state == :sent
    assert conn.status == status
    assert conn.resp_body == body
    conn
  end

  def assert_resp_header(conn, {header, content}) do
    assert get_resp_header(conn, header) == content
    conn
  end
end
