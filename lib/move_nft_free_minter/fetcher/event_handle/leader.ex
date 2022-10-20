defmodule MoveNFTFreeMinter.Fetcher.EventHandle.Leader do
  @moduledoc """
  NOTE: [Refacoty] TaskSupervisor is not a good way, it's better to use DynamicSupervisor
  """

  use GenServer

  require Logger

  alias MoveNFTFreeMinter.Fetcher
  alias Fetcher.{EventHandle, TaskData}

  # milliseconds
  @block_interval 10_000

  @watched_events [
    %{
      account: "0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b",
      event_handle: "0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b::marketplace::MarketEvents",
      field: "list_token_events"
    },
    %{
      account: "0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b",
      event_handle: "0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b::marketplace::MarketEvents",
      field: "buy_token_events"
    }
  ]

  defmodule State do
    defstruct ~w(
      client
      tasks
    )a
  end

  def child_spec([named_arguments]) when is_map(named_arguments),
    do: child_spec([named_arguments, []])

  def child_spec([_named_arguments, gen_server_options] = start_link_arguments)
      when is_list(gen_server_options) do
    Supervisor.child_spec(
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, start_link_arguments},
        type: :supervisor
      },
      []
    )
  end

  def start_link(client, gen_server_options \\ []) do
    GenServer.start_link(__MODULE__, client, gen_server_options)
  end

  def get_entries() do
    GenServer.call(__MODULE__, :get_entries)
  end

  @impl true
  def init(client) do
    state = %State{
      client: client,
      tasks: []
    }

    for item <- @watched_events do
      # Logger.info("start #{inspect(@watched_events)}")
      Process.send_after(
        self(),
        {:fetcher, %TaskData{event_handle: item.event_handle, field: item.field, account: item.account}},
        @block_interval
      )
    end

    {:ok, state}
  end

  @impl true
  def handle_info({:fetcher, event}, %State{client: client, tasks: tasks} = state) do
    %{ref: ref} = Task.Supervisor.async_nolink(EventHandle.TaskSupervisor, Fetcher, :task, [event, client])

    task_data = %TaskData{event | ref: ref}

    {:noreply, %State{state | tasks: [task_data | tasks]}}
  end

  @impl true
  def handle_info({ref, previous_number}, %State{tasks: tasks, client: client} = state) do
    Process.demonitor(ref, [:flush])

    case Enum.find_index(tasks, &(&1.ref == ref)) do
      nil ->
        # 异常处理, 建议重启程序
        Logger.error("Tried to update non-existing task: #{inspect(ref)}")
        # Process.send_after(self(), :fetcher, @block_interval)
        # retry

        {:noreply, %State{state | tasks: []}}

      index ->
        Process.sleep(@block_interval)

        old_task_data = Enum.at(tasks, index)
        %{ref: new_task_ref} = Task.Supervisor.async_nolink(EventHandle.TaskSupervisor, Fetcher, :task, [%TaskData{old_task_data | previous_number: previous_number}, client])
        new_task_data = %TaskData{old_task_data | ref: new_task_ref, previous_number: previous_number}

        Logger.info("Start new task")

        new_tasks = List.replace_at(tasks, index, new_task_data)

        {:noreply, %State{state | tasks: new_tasks}}
    end
  end

  @impl true
  def handle_info({ref, {:error, :etimedout}}, %State{tasks: tasks} = state) do
    case Enum.find_index(tasks, &(&1.ref == ref)) do
      nil ->
        Logger.error("Tried to update non-existing task: #{inspect(ref)}")
        restart_all_tasks(state)

      index ->
        Logger.warn("#{inspect(ref)} timeout, restaring task")

        start_new_task(index, state)
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, %State{tasks: tasks} = state) do
    case Enum.find_index(tasks, &(&1.ref == ref)) do
      nil ->
        Logger.error("Tried to update non-existing task: #{inspect(ref)}")
        restart_all_tasks(state)

      index ->
        Logger.error("exited with reason (#{inspect(reason)})")
        start_new_task(index, state)
    end
  end

  defp restart_all_tasks(%{tasks: tasks} = state) do
    Process.sleep(@block_interval)

    for item <- tasks do
      Process.send_after(
        self(),
        {:fetcher, %TaskData{event_handle: item.event_handle, field: item.field, account: item.account}},
        @block_interval
      )
    end

    {:noreply, %State{state | tasks: []}}
  end

  defp start_new_task(index, %State{tasks: tasks, client: client} = state) do
    Process.sleep(@block_interval)

    old_task_data = Enum.at(tasks, index)
    %{ref: new_task_ref} = Task.Supervisor.async_nolink(EventHandle.TaskSupervisor, Fetcher, :task, [old_task_data, client])
    new_task_data = %TaskData{old_task_data | ref: new_task_ref}
    new_tasks = List.replace_at(tasks, index, new_task_data)

    {:noreply, %State{state | tasks: new_tasks}}
  end
end
