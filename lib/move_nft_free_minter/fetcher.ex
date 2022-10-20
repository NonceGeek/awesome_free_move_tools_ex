defmodule MoveNFTFreeMinter.Fetcher do
  @moduledoc false

  alias MoveNFTFreeMinter.{Explorer, Import, AptosRPC, Fetcher}

  defmodule TaskData do
    @moduledoc """
    %Task{} with state && result && contract_name
    """
    defstruct event_handle: nil,
              account: nil,
              field: nil,
              previous_number: nil,
              ref: nil

    def event_handle_id(%__MODULE__{event_handle: event_handle, field: field}), do: event_handle <> "::" <> field
  end

  def task(%{previous_number: nil, account: account} = task_data, client) do
    previous_number = Explorer.get_max_sequence_number_by_event_handle(account, TaskData.event_handle_id(task_data))

    task(%TaskData{task_data | previous_number: previous_number}, client)
  end

  def task(%{previous_number: previous_number} = task_data, client) do
    # case fetch_and_import_events(task_data, client) do
    #   {:ok, %{events: events}} when events != [] ->
    #     events
    #     |> Enum.max_by(&Map.get(&1, :sequence_number))
    #     |> Map.get(:sequence_number)
    #     |> Kernel.+(1)

    #   {:ok, _} ->
    #     previous_number

    #     # {:error, _} ->
    #     #   previous_number
    # end
  end

  def get_withdraw_events(account, client, sequence_number) do
    task_data = %TaskData{previous_number: sequence_number, account: account, event_handle: "0x3::token::TokenStore", field: "withdraw_events"}

    task(task_data, client)
  end

  def get_deposit_events(account, client, sequence_number) do
    task_data = %TaskData{previous_number: sequence_number, account: account, event_handle: "0x3::token::TokenStore", field: "deposit_events"}

    task(task_data, client)
  end

  defp fetch_and_import_events(%{previous_number: previous_number, account: account, field: field, event_handle: event_handle} = task_data, client) do
    with {:ok, event_list} <- AptosRPC.get_events(client, account, event_handle, field, start: previous_number),
         {:ok, import_list} <- Fetcher.Transform.params_set(event_list, task_data) do
      {:ok, result} = Import.run(import_list)
      async_fetcher(result, client)

      {:ok, result}
    end
  end

  defp async_fetcher(%{tokens: tokens}, client) do
    tokens
    |> Enum.each(fn item ->
      %{token_id: item.token_id, client: client.endpoint}
      |> Explorer.Job.TokenData.new()
      |> Oban.insert()
    end)
  end

  defp async_fetcher(_, _), do: :ok
end
