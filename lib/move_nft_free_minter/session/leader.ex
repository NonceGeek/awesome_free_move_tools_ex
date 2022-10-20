defmodule MoveNFTFreeMinter.Session.Leader do
  @moduledoc false

  alias MoveNFTFreeMinter.Session
  alias MoveNFTFreeMinter.Session.{Utils, Tracker}

  def create_session(opts \\ []) do
    {:ok, client} = MoveNFTFreeMinter.AptosRPC.connect()
    id = Utils.random_node_aware_id()

    opts =
      opts
      |> Keyword.put(:id, id)
      |> Keyword.put(:client, client)

    case DynamicSupervisor.start_child(MoveNFTFreeMinter.SessionSupervisor, {Session, opts}) do
      {:ok, pid} ->
        session = Session.get_by_pid(pid)

        case Tracker.track_session(session) do
          :ok ->
            {:ok, session}

          {:error, reason} ->
            Session.close(pid)
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns all the running sessions.
  """
  @spec list_sessions() :: list(Session.t())
  def list_sessions() do
    Tracker.list_sessions()
  end

  @doc """
  Returns tracked session with the given id.
  """
  @spec fetch_session(Session.id()) :: {:ok, Session.t()} | :error
  def fetch_session(id) do
    case Tracker.fetch_session(id) do
      {:ok, session} ->
        {:ok, session}

      :error ->
        # The local tracker server doesn't know about this session,
        # but it may not have propagated yet, so we extract the session
        # node from id and ask the corresponding tracker directly
        with {:ok, other_node} when other_node != node() <- Utils.node_from_node_aware_id(id),
             {:ok, session} <- :rpc.call(other_node, Tracker, :fetch_session, [id]) do
          {:ok, session}
        else
          _ -> :error
        end
    end
  end

  @doc """
  Updates the given session info across the cluster.
  """
  @spec update_session(Session.t()) :: :ok | {:error, any()}
  def update_session(session) do
    Tracker.update_session(session)
  end

  @doc """
  Subscribes to update in sessions list.

  ## Messages

    * `{:session_created, session}`
    * `{:session_updated, session}`
    * `{:session_closed, session}`

  """
  @spec subscribe() :: :ok | {:error, term()}
  def subscribe() do
    Phoenix.PubSub.subscribe(MoveNFTFreeMinter.PubSub, "tracker_sessions")
  end
end
