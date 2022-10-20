defmodule MoveNFTFreeMinter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ensure_upload_dir_exists()

    children = [
      # Start the Ecto repository
      MoveNFTFreeMinter.Repo,
      # Start the Telemetry supervisor
      MoveNFTFreeMinterWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MoveNFTFreeMinter.PubSub},
      # Start the Endpoint (http/https)
      MoveNFTFreeMinterWeb.Endpoint,
      {Oban, Application.fetch_env!(:move_nft_free_minter, Oban)},
      # {MoveNFTFreeMinter.Fetcher.Supervisor, []},
      # Start the tracker server on this node
      {MoveNFTFreeMinter.Session.Tracker, pubsub_server: MoveNFTFreeMinter.PubSub},
      # Start the supervisor dynamically managing sessions
      {DynamicSupervisor, name: MoveNFTFreeMinter.SessionSupervisor, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MoveNFTFreeMinter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MoveNFTFreeMinterWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def ensure_upload_dir_exists() do
    upload_dir = Path.join([Application.app_dir(:move_nft_free_minter), "/priv/static/uploads/"])

    ensure_dir_exists(upload_dir)
    :ok
  end

  def ensure_dir_exists(dir) do
    unless File.exists?(dir) do
      File.mkdir!(dir)
    end

    :ok
  end
end
