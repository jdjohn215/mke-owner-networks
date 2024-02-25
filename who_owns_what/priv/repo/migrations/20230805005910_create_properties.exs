defmodule WhoOwnsWhat.Repo.Migrations.CreateProperties do
  use Ecto.Migration

  def change do
    create table(:properties) do
      add :taxkey, :string
      add :house_number_low, :integer
      add :house_number_high, :integer
      add :house_number_suffix, :string
      add :street_direction, :string
      add :street, :string
      add :street_type, :string
      add :c_a_class, :string
      add :land_use_gp, :string
      add :c_a_total, :integer
      add :number_units, :integer
      add :owner_name_1, :string
      add :owner_name_2, :string
      add :owner_name_3, :string
      add :owner_address, :string
      add :owner_city_state, :string
      add :owner_zip_code, :string
      add :geo_zip_code, :string
      add :calculated_owner_occupied, :boolean, default: false, null: false
      add :owner_occupied, :boolean, default: false, null: false
      add :geo_alder, :string
      add :wdfi_address, :string
      add :dns_covered_days, :integer
      add :dns_covered_unit_years, :float
      add :total_dns_orders, :integer
      add :total_dns_violations, :integer
      add :ownership_dns_orders, :integer
      add :ownership_dns_violations, :integer
      add :eviction_filings, :integer
      add :eviction_orders, :integer
      add :convey_date, :date
      add :latitude, :float
      add :longitude, :float

      timestamps()
    end

    execute(
      """
      CREATE VIRTUAL TABLE properties_fts USING fts5(
        taxkey UNINDEXED,
        owner_name_1,
        owner_group_name,
        full_address,
        tokenize="trigram"
      );
      """,
      """
      DROP TABLE properties_fts;
      """
    )

    create index(:properties, [:taxkey], unique: true)
  end
end
