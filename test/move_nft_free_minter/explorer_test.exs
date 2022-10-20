defmodule MoveNFTFreeMinter.ExplorerTest do
  @moduledoc false

  use MoveNFTFreeMinter.DataCase

  alias MoveNFTFreeMinter.{Explorer, AptosRPC}

  setup_all do
    {:ok, client} = AptosRPC.connect()
    {:ok, client: client}
  end

  test "get_deposit_events", %{client: client} do
    Explorer.get_deposit_events(
      client,
      "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490"
    )
  end

  test "get_withdraw_events", %{client: client} do
    Explorer.get_withdraw_events(
      client,
      "0xdc4e806913a006d86da8327a079d794435e2e3117fd418062ddf43943d663490"
    )
  end
end
