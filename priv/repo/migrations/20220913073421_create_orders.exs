defmodule MoveNFTFreeMinter.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :version, :integer
      add :key, :string
      add :sequence_number, :integer
      add :type, :string
      add :data, :map
      add :token_id, :map
      add :status, :string
      add :price, :decimal
      add :maker, :string
      add :taker, :string
      add :timestamp, :string
      add :order_id, :string

      timestamps()
    end

    create index(:orders, [:token_id])
    create index(:orders, [:maker])
    create index(:orders, [:taker])
    create index(:orders, [:status])
    create index(:orders, [:version])
    # create unique_index(:orders, [:sequence_number])
    create unique_index(:orders, [:order_id])
    # create unique_index(:orders, [:token_id, :status], where: "status = 'ongoing'")
  end
end
