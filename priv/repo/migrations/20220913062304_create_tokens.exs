defmodule MoveNFTFreeMinter.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :creator, :string
      add :token_id, :map
      add :collection_name, :string
      add :name, :string
      add :uri, :string
      add :description, :string
      add :maximum, :string
      add :supply, :string
      add :property_version, :integer

      add :last_fetched_at, :utc_datetime_usec

      add :royalty, :map
      add :mutability_config, :map
      add :largest_property_version, :string
      add :default_properties, :map

      timestamps()
    end

    create unique_index(:tokens, [:token_id])
    create index(:tokens, [:last_fetched_at])
    create index(:tokens, [:collection_name, :name])
  end
end
