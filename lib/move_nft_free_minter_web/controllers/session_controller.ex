defmodule MoveNFTFreeMinterWeb.SessionController do
  @moduledoc false

  use MoveNFTFreeMinterWeb, :controller

  alias MoveNFTFreeMinter.{Accounts, Session}
  alias MoveNFTFreeMinterWeb.UserAuth

  action_fallback MoveNFTFreeMinterWeb.FallbackController

  def create(conn, params) do
    with {:ok, user} <- Accounts.verify_wallet_address(params) do
      # add fetcher
      Session.Leader.create_session(address: user.address)

      UserAuth.log_in_user(conn, user)
    end
  end

  def delete(conn, _params), do: UserAuth.log_out_user(conn)
end
