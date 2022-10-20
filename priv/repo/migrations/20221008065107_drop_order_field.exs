defmodule MoveNFTFreeMinter.Repo.Migrations.DropOrderField do
  use Ecto.Migration

  def change do
    alter table("orders") do
      remove_if_exists :key, :string
    end
  end
end
