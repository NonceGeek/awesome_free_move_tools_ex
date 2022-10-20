defmodule MoveNFTFreeMinter.Explorer do
  @moduledoc """
  The Explorer context.
  """

  require Integer

  import Ecto.Query

  alias MoveNFTFreeMinter.{Repo, Turbo}

  alias MoveNFTFreeMinter.Explorer.Model.{Order, Event, Token}

  @doc """
  list account tokens
  """
  def list_account_tokens(account) do
    from(e in Event,
      where: e.account == ^account and e.type in ["0x3::token::DepositEvent", "0x3::token::WithdrawEvent"],
      order_by: [desc: e.version],
      preload: [:token]
    )
    |> Repo.all()
    |> case do
      [] ->
        []

      value ->
        value
        |> Enum.group_by(& &1.token_id)
        |> Enum.map(fn {_token_id, token_events} ->
          case token_events |> length() |> Integer.is_even() do
            true ->
              nil

            false ->
              List.first(token_events)
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> List.flatten()
    end
  end

  @doc """
  list orders
  """
  def list_orders() do
    from(o in Order, where: o.status == "ongoing", preload: [:token])
    |> Repo.all()
  end

  @doc """
  list ongoing orders
  """
  def list_user_ongoing_orders(account) do
    from(o in Order,
      where: o.status == "ongoing",
      where: o.maker == ^account,
      preload: [:token]
    )
    |> Repo.all()
  end

  @doc """
  get account max sequence number
  """
  def get_max_sequence_number_by_event_handle(account, event_handle_id) do
    case Event.get_max_sequence_number_by_event_handle(account, event_handle_id) do
      nil -> 0
      value -> value + 1
    end
  end

  @doc """
  find and update token
  """
  def find_and_update_token(clauses, attrs) do
    Token
    |> Repo.get_by(clauses)
    |> case do
      nil ->
        {:error, :not_found}

      result ->
        result
        |> result.__struct__.changeset(attrs)
        |> Repo.update()
    end
  end

  def get_event(id), do: Turbo.get(Event, id, preload: [:token])

  # def get_deposit_events(address, client, options) do
  # end

  # def get_withdraw_events(address, client, options) do
  # end
end
