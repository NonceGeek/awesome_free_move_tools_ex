defmodule MoveNFTFreeMinter.AptosRpcTest do
  @moduledoc false

  use MoveNFTFreeMinter.DataCase
  alias MoveNFTFreeMinter.AptosRPC

  setup_all do
    {:ok, client} = AptosRPC.connect()
    {:ok, client: client}
  end

  test "connect", %{client: client} do
    assert client.chain_id == 27
  end

  test "get_collection_data", %{client: client} do
    {:ok, result} =
      AptosRPC.get_collection_data(
        client,
        "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
        "DummyDog"
      )

    assert %{
             description: "_1200_dollars_per_hour",
             maximum: "18446744073709551615",
             mutability_config: %{description: false, maximum: false, uri: false},
             name: "DummyDog",
             supply: "1",
             uri: "https://github.com/amovane/aptos-NFT-marketplace"
           } == result
  end

  test "get token data", %{client: client} do
    {:ok, result} =
      AptosRPC.get_token_data(
        client,
        "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
        "DummyDog",
        "DummyDog 1"
      )

    assert %{
             default_properties: %{map: %{data: []}},
             description: "about DummyDog 1",
             largest_property_version: "0",
             maximum: "18446744073709551615",
             mutability_config: %{
               description: false,
               maximum: false,
               properties: false,
               royalty: false,
               uri: false
             },
             name: "DummyDog 1",
             royalty: %{
               payee_address: "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490",
               royalty_points_denominator: "100",
               royalty_points_numerator: "0"
             },
             supply: "1",
             uri: "https://nftstorage.link/ipfs/bafybeicj7c4smq5nn4n62zspw3np4put7s2wpeplaayvyo2b3s4c33jiki/1.jpg"
           } == result
  end
end
