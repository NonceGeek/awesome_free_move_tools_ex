defmodule MoveNFTFreeMinter.Explorer.Job.TokenData do
  @moduledoc false

  require Logger

  use Oban.Worker, queue: :default, priority: 1, max_attempts: 20

  alias MoveNFTFreeMinter.{AptosRPC, Explorer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"token_id" => %{"token_data_id" => token_data_id} = token_id, "client" => client_endpoint} = _args}) do
    Logger.info("start token job #{inspect(token_id)}")

    {:ok, client} = AptosRPC.connect(client_endpoint)
    %{"collection" => collection_name, "creator" => creator, "name" => token_name} = token_data_id

    with {:ok, result} <- AptosRPC.get_token_data(client, creator, collection_name, token_name) do
      attrs = %{
        uri: result.uri,
        description: result.description,
        supply: result.supply,
        royalty: result.royalty,
        mutability_config: result.mutability_config,
        maximum: result.maximum,
        largest_property_version: result.largest_property_version,
        default_properties: result.default_properties,
        last_fetched_at: DateTime.utc_now()
      }

      Explorer.find_and_update_token(%{token_id: token_id}, attrs)
    else
      _ ->
        {:error, :retry_fetcher_token_data}
    end
  end
end
