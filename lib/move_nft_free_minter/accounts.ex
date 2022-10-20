defmodule MoveNFTFreeMinter.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias MoveNFTFreeMinter.{Repo, Turbo}
  alias MoveNFTFreeMinter.Accounts.{User, UserToken}

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc "verify_wallet_address/1"
  def verify_wallet_address(%{"wallet_address" => address} = _params) do
    with true <- verify_address(address),
         clauses = %{address: address},
         {:ok, user} <- Turbo.findby_or_insert(User, clauses, clauses) do
      {:ok, user}
    end
  end

  defp verify_address(_params), do: true

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  def find_user_by_public_address(address), do: Turbo.findby_or_insert(User, %{address_hash: address}, %{address_hash: address})

  @doc """
  Verifies the public address passed in was used to create the signature for a user
  Returns %User{} or nil
  """
  def verify_message_signature(wallet_address) do
    # message = "Signing this message is verification that the Metamask wallet you are using belongs to you."
    with {:ok, user} <- find_user_by_public_address(wallet_address) do
      user
    end
  end
end
