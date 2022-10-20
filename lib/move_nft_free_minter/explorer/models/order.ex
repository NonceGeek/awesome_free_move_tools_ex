defmodule MoveNFTFreeMinter.Explorer.Model.Order do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias MoveNFTFreeMinter.Explorer.Model.Token

  @timestamps_opts [type: :utc_datetime_usec]
  schema "orders" do
    field :data, :map
    field :maker, :string
    field :taker, :string
    field :order_id, :string
    field :price, :decimal
    field :sequence_number, :integer
    field :timestamp, :string
    # field :token_id, :map
    field :type, :string
    field :status, :string
    field :version, :integer

    belongs_to :token, Token, foreign_key: :token_id, type: :map, references: :token_id

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    required_fields = ~w(
      sequence_number
      data
      token_id
      price
      maker
      timestamp
      order_id
    )a

    optional_fields = ~w(
      version
      type
      status
      taker
    )a

    order
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
  end
end
