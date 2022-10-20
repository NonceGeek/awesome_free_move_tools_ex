defmodule MoveNFTFreeMinter.Explorer.Model.Token do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  schema "tokens" do
    field :token_id, :map
    field :collection_name, :string
    field :creator, :string
    field :description, :string
    field :maximum, :string
    field :name, :string
    field :supply, :string
    field :uri, :string
    field :property_version, :integer
    field :royalty, :map
    field :mutability_config, :map
    field :largest_property_version, :string
    field :default_properties, :map
    field :last_fetched_at, :utc_datetime_usec

    timestamps()
  end

  @doc false
  def changeset(token, attrs) do
    required_fields = ~w(
      token_id
      creator
      collection_name
      name
      property_version
    )a

    optional_fields = ~w(
      uri
      description
      royalty
      mutability_config
      default_properties
      largest_property_version
      last_fetched_at
      maximum
      supply
    )a

    token
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
  end

  def input_changeset(token, attrs) do
    required_fields = ~w(
      collection_name
      name
      description
      uri
    )a

    token
    |> cast(attrs, required_fields)
    |> validate_required(required_fields)
  end
end
