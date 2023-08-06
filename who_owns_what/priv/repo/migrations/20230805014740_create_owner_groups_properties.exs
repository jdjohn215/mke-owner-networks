defmodule WhoOwnsWhat.Repo.Migrations.CreateOwnerGroupsProperties do
  use Ecto.Migration

  def change do
    create table(:owner_groups_properties) do
      add :taxkey, :string
      add :name, :string

      timestamps()
    end

    create index(:owner_groups_properties, [:taxkey], unique: true)
    create index(:owner_groups_properties, [:name])
  end
end
