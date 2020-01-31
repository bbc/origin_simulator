defmodule MultiRouteOriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  import TestHelpers

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET pages" do
    test "for a wildcard route" do
      payload = [
        %{
          "route" => "/*",
          "body" => "I am ok",
          "stages" => [%{"at" => 0, "status" => 200, "latency" => 0}]
        }
      ]

      conn(:post, "/#{admin_domain()}/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])
      Process.sleep(20)

      path = "/any_path"
      conn = conn(:get, path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "I am ok"

      path = "/another_path"
      conn = conn(:get, path)
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "I am ok"
    end
  end
end
