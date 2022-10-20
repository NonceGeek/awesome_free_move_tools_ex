defmodule MoveNFTFreeMinter.Fetcher.EventHandle.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  alias MoveNFTFreeMinter.Fetcher

  def child_spec([init_arguments]) do
    child_spec([init_arguments, []])
  end

  def child_spec([_init_arguments, _gen_server_options] = start_link_arguments) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, start_link_arguments},
      type: :supervisor
    }

    Supervisor.child_spec(default, [])
  end

  def start_link(arguments, gen_server_options \\ []) do
    Supervisor.start_link(__MODULE__, arguments, gen_server_options)
  end

  @impl Supervisor
  def init(client) do
    Logger.info("Started EventHandle")

    Supervisor.init(
      [
        {Task.Supervisor, name: Fetcher.EventHandle.TaskSupervisor},
        {Fetcher.EventHandle.Leader, [client, [name: Fetcher.EventHandle.Leader]]}
      ],
      strategy: :one_for_one
    )
  end
end
