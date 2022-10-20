defmodule MoveNFTFreeMinter.Repo.Migrations.DropEventField do
  use Ecto.Migration

  def change do
    alter table("events") do
      remove_if_exists :key, :string
    end

    drop_if_exists unique_index(:events, [:sequence_number, :key])
    create unique_index(:events, [:sequence_number, :type])
  end
end
