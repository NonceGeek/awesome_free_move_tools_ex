defmodule MoveNFTFreeMinter.Import.Runner.Events do
  @moduledoc false

  alias Ecto.Multi

  alias MoveNFTFreeMinter.Import
  alias MoveNFTFreeMinter.Explorer.Model.Event

  @timeout 60_000

  def timeout, do: @timeout
  def option_key, do: :events
  def ecto_schema_module, do: Event

  def run(multi, changes_list, %{timestamps: timestamps} = options) do
    insert_options =
      options
      |> Map.get(option_key(), %{})
      |> Map.take(~w(on_conflict timeout)a)
      |> Map.put_new(:timeout, @timeout)
      |> Map.put(:timestamps, timestamps)

    Multi.run(multi, :events, fn repo, _ ->
      insert(repo, changes_list, insert_options)
    end)
  end

  def insert(repo, changes_list, %{timeout: timeout, timestamps: timestamps} = _options)
      when is_list(changes_list) do
    {:ok, _} =
      Import.insert_changes_list(
        repo,
        changes_list,
        conflict_target: [:type, :sequence_number],
        on_conflict: :nothing,
        for: Event,
        returning: true,
        timeout: timeout,
        timestamps: timestamps
      )
  end
end

# withdraw_event

# 	{
# 		"version": "20194971",
# 		"key": "0x0800000000000000dc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
# 		"sequence_number": "0",
# 		"type": "0x3::token::WithdrawEvent",
# 		"data": {
# 			"amount": "1",
# 			"id": {
# 				"property_version": "0",
# 				"token_data_id": {
# 					"collection": "DummyDog",
# 					"creator": "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
# 					"name": "DummyDog 1"
# 				}
# 			}
# 		}
# 	}

# deposit events

# {
#   "version": "20192337",
#   "key": "0x0700000000000000dc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
#   "sequence_number": "4",
#   "type": "0x3::token::DepositEvent",
#   "data": {
#     "amount": "1",
#     "id": {
#       "property_version": "0",
#       "token_data_id": {
#         "collection": "DummyDog",
#         "creator": "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
#         "name": "DummyDog 1"
#       }
#     }
#   }
# }
