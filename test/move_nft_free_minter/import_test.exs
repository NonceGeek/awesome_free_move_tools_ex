defmodule MoveNFTFreeMinter.ImportTest do
  @moduledoc false

  use MoveNFTFreeMinter.DataCase

  alias MoveNFTFreeMinter.{Explorer, AptosRPC}

  test "Import.run()" do
    event_data = %{
      data: %{
        market_id: %{
          market_address: "0x165a89c2f0a66ebfaef5cccf699d34981b5959916c6cadab71f69f74daa69d02",
          market_name: "_1200_dollars_per_hour"
        },
        offer_id: "29",
        price: "120",
        seller: "0xc842c666c8e6b0bab13d8c71ef1fcb15f5d84700aba44691322854f360055883",
        timestamp: "1663050311176085",
        token_id: %{
          property_version: "0",
          token_data_id: %{
            collection: "$120/H",
            creator: "0xc842c666c8e6b0bab13d8c71ef1fcb15f5d84700aba44691322854f360055883",
            name: "$120/H"
          }
        }
      },
      key: "0x0500000000000000165a89c2f0a66ebfaef5cccf699d34981b5959916c6cadab71f69f74daa69d02",
      sequence_number: "19",
      type: "0x165a89c2f0a66ebfaef5cccf699d34981b5959916c6cadab71f69f74daa69d02::marketplace::ListTokenEvent",
      version: "21288836"
    }

    order_attrs = %{
      data: event_data.data,
      version: event_data.version,
      type: event_data.type,
      sequence_number: event_data.sequence_number,
      key: event_data.key,
      token_id: event_data.data.token_id,
      status: "ongoing",
      price: event_data.data.price,
      maker: event_data.data.seller,
      timestamp: event_data.data.timestamp,
      order_id: event_data.data.offer_id
    }

    token_attrs = %{
      sequence_number: event_data.sequence_number,
      token_id: event_data.data.token_id,
      data: event_data.data,
      account: "0x165a89c2f0a66ebfaef5cccf699d34981b5959916c6cadab71f69f74daa69d02",
      version: event_data.version,
      type: event_data.type,
      key: event_data.key
    }

    import_list = %{
      orders: %{params: [order_attrs]},
      events: %{params: [token_attrs]}
    }

    {:ok, %{orders: result_orders, events: result_events}} = MoveNFTFreeMinter.Import.run(import_list)

    assert length(result_events) == 1
    assert length(result_orders) == 1

    {:ok, result} = MoveNFTFreeMinter.Import.run(import_list)
    assert %{events: [], orders: []} == result
  end
end
