use Mix.Config

config :origin_simulator, http_port: 8081
config :origin_simulator, http_client: OriginSimulator.HTTP.MockClient
