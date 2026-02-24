defmodule WhoOwnsWhat.Repo.Migrations.AddCompleteAddresses do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :complete_addresses, :text
    end
  end
end
