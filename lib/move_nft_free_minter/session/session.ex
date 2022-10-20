defmodule MoveNFTFreeMinter.Session do
  @moduledoc false

  use GenServer, restart: :temporary

  require Logger

  alias MoveNFTFreeMinter.Fetcher

  defmodule State do
    @moduledoc false

    defstruct ~w(
      id
      pid
      session_id
      client
      address
      deposit_sequence_number
      withdraw_sequence_number
    )a
  end

  @timeout :infinity
  @interval 5_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Fetches session information from the session server.
  """
  def get_by_pid(pid) do
    GenServer.call(pid, :describe_self, @timeout)
  end

  def close(_pid) do
    :ok
  end

  ## Callbacks

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    address = Keyword.fetch!(opts, :address)
    client = Keyword.fetch!(opts, :client)

    state = %State{
      client: client,
      session_id: id,
      address: address,
      deposit_sequence_number: nil,
      withdraw_sequence_number: nil
    }

    send(self(), :fetch_deposit_events)
    send(self(), :fetch_withdraw_events)

    {:ok, state}
  end

  @impl true
  def handle_call(:describe_self, _from, state) do
    {:reply, self_from_state(state), state}
  end

  @impl true
  def handle_info(:fetch_deposit_events, %State{client: client, address: address, deposit_sequence_number: deposit_sequence_number} = state) do
    deposit_sequence_number = Fetcher.get_deposit_events(address, client, deposit_sequence_number)
    Process.send_after(self(), :fetch_deposit_events, @interval)

    {:noreply, %State{state | deposit_sequence_number: deposit_sequence_number}}
  end

  @impl true
  def handle_info(:fetch_withdraw_events, %State{client: client, address: address, withdraw_sequence_number: withdraw_sequence_number} = state) do
    withdraw_sequence_number = Fetcher.get_withdraw_events(address, client, withdraw_sequence_number)
    Process.send_after(self(), :fetch_withdraw_events, @interval)

    {:noreply, %State{state | withdraw_sequence_number: withdraw_sequence_number}}
  end

  defp self_from_state(state) do
    %State{
      id: state.session_id,
      pid: self(),
      client: state.client,
      address: state.address
    }
  end
end
