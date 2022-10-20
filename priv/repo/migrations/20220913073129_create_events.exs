defmodule MoveNFTFreeMinter.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :version, :integer
      add :key, :string
      add :type, :string
      add :sequence_number, :integer
      add :account, :string
      add :amount, :string
      add :token_id, :map
      add :event_handle_id, :string

      add :data, :map

      timestamps()
    end

    create unique_index(:events, [:sequence_number, :key])

    create index(:events, [:token_id])
    create index(:events, [:event_handle_id])
    create index(:events, [:version])
  end
end
