defmodule MoveNFTFreeMinter.Explorer.Model.Event do
  @moduledoc false

  import Ecto.Query, warn: false

  use Ecto.Schema
  import Ecto.Changeset

  alias MoveNFTFreeMinter.Repo

  alias MoveNFTFreeMinter.Explorer.Model.Token

  @timestamps_opts [type: :utc_datetime_usec]
  schema "events" do
    field :account, :string
    field :amount, :string
    field :data, :map
    field :sequence_number, :integer
    field :event_handle_id, :string
    field :type, :string
    field :version, :integer

    belongs_to :token, Token, foreign_key: :token_id, type: :map, references: :token_id

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    required_fields = ~w(
      sequence_number
      event_handle_id
      account
      token_id
      type
    )a

    optional_fields = ~w(
      version
      type
      account
      amount
      data
    )a

    event
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
  end

  def get_max_sequence_number_by_event_handle(account, event_handle_id) do
    from(event in __MODULE__,
      where: event.account == ^account and event.event_handle_id == ^event_handle_id,
      order_by: [desc: event.sequence_number],
      limit: 1,
      select: event.sequence_number
    )
    |> Repo.one()
  end
end
