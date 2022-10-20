import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :move_nft_free_minter, MoveNFTFreeMinter.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "move_nft_free_minter_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :move_nft_free_minter, MoveNFTFreeMinterWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gzJ6GDLCfw+NaPB0uQyt9Vg9gJha3+qWE6mGPjtSh28UaPqzqL518q8z+spCg9IC",
  server: false

# In test we don't send emails.
config :move_nft_free_minter, MoveNFTFreeMinter.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn
config :move_nft_free_minter, Oban, testing: :inline

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
