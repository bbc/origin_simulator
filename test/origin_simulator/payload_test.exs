defmodule OriginSimulator.PayloadTest do
  use ExUnit.Case, async: true
  alias OriginSimulator.{RecipeRoute,Payload}

  setup do
    payloads_store = start_supervised!(Payload)
    ets_table = GenServer.call(payloads_store, :state)

    %{payloads_store: payloads_store, ets_table: ets_table}
  end
  
  describe "update payloads" do
    test "with origin payload", %{payloads_store: payloads_store, ets_table: ets_table} do
      Payload.update_payloads(payloads_store, [%RecipeRoute{origin: "https://www.bbc.co.uk"}])

      assert :ets.lookup(ets_table, "/*") == [{"/*", "some content from origin"}]
    end

    test "with body payload", %{payloads_store: payloads_store, ets_table: ets_table} do
      Payload.update_payloads(payloads_store, [%RecipeRoute{body: "foo"}])

      assert :ets.lookup(ets_table, "/*") == [{"/*", "foo"}]
    end

    test "with random content", %{payloads_store: payloads_store, ets_table: ets_table} do
      Payload.update_payloads(payloads_store, [%RecipeRoute{random_content: "1kb"}])
      [{"/*", payload}] = :ets.lookup(ets_table, "/*")

      assert String.length(payload) == 1024
    end
  end

  describe "body" do
    test "with origin payload", %{payloads_store: payloads_store} do
      Payload.update_payloads(payloads_store,
        [%RecipeRoute{pattern: "/origin", origin: "https://www.bbc.co.uk"}])

      assert Payload.body(payloads_store, 200, "/origin") == {:ok, "some content from origin"}
    end

    test "with body payload", %{payloads_store: payloads_store} do
      Payload.update_payloads(payloads_store, [%RecipeRoute{pattern: "/body", body: "foo"}])

      assert Payload.body(payloads_store, 200, "/body") == {:ok, "foo"}
    end

    test "with random content payload", %{payloads_store: payloads_store} do
      Payload.update_payloads(payloads_store,
        [%RecipeRoute{pattern: "/random", random_content: "1kb"}])
      {:ok, random_payload_body } = Payload.body(payloads_store, 200, "/random")

      assert String.length(random_payload_body) == 1024
    end

    test "always return an error body for 5xx", %{payloads_store: payloads_store} do
      Payload.update_payloads(payloads_store, [%RecipeRoute{pattern: "/foo", body: "bar"}])

      assert Payload.body(payloads_store, 503, "/foo") == {:ok, "Error 503"}
    end

    test "always return 'Not Found' for 404s", %{payloads_store: payloads_store} do
      Payload.update_payloads(payloads_store, [%RecipeRoute{pattern: "/foo", body: "bar"}])

      assert Payload.body(payloads_store, 404, "/foo") == {:ok, "Not found"}
    end

    test "errors if the the path is not in the ets store", %{payloads_store: payloads_store} do
      assert Payload.body(payloads_store, 200, "/foo") == {:error, "Could not find the payload in the cache"}
    end
  end
end
