defmodule WhoOwnsWhat.Repo.Migrations.CreateOwnerGroupsProperties do
  use Ecto.Migration

  def change do
    create table(:owner_groups_properties) do
      add :taxkey, :string
      add :owner_group_name, :string
      add :wdfi_group_id, :string
      add :group_source, :string

      timestamps()
    end

    create index(:owner_groups_properties, [:taxkey], unique: true)
    create index(:owner_groups_properties, [:owner_group_name])

    create table(:owner_groups) do
      add :name, :string
      add :total_assessed_value, :integer
      add :number_properties, :integer
      add :number_units, :integer
      add :eviction_orders, :integer
      add :eviction_filings, :integer
      add :eviction_covered_unit_years, :float
      add :annual_eviction_filing_rate_per_unit, :float
      add :annual_eviction_order_rate_per_unit, :float
      add :dns_covered_unit_years, :float
      add :ownership_dns_orders, :integer
      add :ownership_dns_violations, :integer
      add :ownership_dns_violation_unit_rate_annual, :float
      add :total_dns_orders, :integer
      add :total_dns_violations, :integer

      timestamps()
    end

    create index(:owner_groups, [:name], unique: true)
  end
end
