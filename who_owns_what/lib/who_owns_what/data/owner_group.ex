defmodule WhoOwnsWhat.Data.OwnerGroup do
  use Ecto.Schema
  import Ecto.Changeset
  alias WhoOwnsWhat.Data.OwnerGroupProperty

  schema "owner_groups" do
    field :name, :string
    field :total_assessed_value, :integer
    field :number_properties, :integer
    field :number_units, :integer
    field :eviction_orders, :integer
    field :eviction_filings, :integer
    field :eviction_covered_unit_years, :float
    field :annual_eviction_filing_rate_per_unit, :float
    field :annual_eviction_order_rate_per_unit, :float
    field :dns_covered_unit_years, :float
    field :ownership_orders, :integer
    field :ownership_violations, :integer
    field :ownership_violation_unit_rate_annual, :float
    field :total_orders, :integer
    field :total_violations, :integer

    timestamps()

    has_many :owner_groups_properties, OwnerGroupProperty,
      foreign_key: :owner_group_name,
      references: :name

    has_many :properties, through: [:owner_groups_properties, :property]
  end

  @doc false
  def changeset(owner_group, attrs) do
    owner_group
    |> cast(attrs, [
      :name,
      :total_assessed_value,
      :number_properties,
      :number_units,
      :eviction_orders,
      :eviction_filings,
      :eviction_covered_unit_years,
      :annual_eviction_filing_rate_per_unit,
      :annual_eviction_order_rate_per_unit,
      :dns_covered_unit_years,
      :ownership_orders,
      :ownership_violations,
      :ownership_violation_unit_rate_annual,
      :total_orders,
      :total_violations
    ])
    |> validate_required([
      :name,
      :total_assessed_value,
      :number_properties,
      :number_units,
      :eviction_orders,
      :eviction_filings,
      :eviction_covered_unit_years,
      :annual_eviction_filing_rate_per_unit,
      :annual_eviction_order_rate_per_unit,
      :dns_covered_unit_years,
      :ownership_orders,
      :ownership_violations,
      :ownership_violation_unit_rate_annual,
      :total_orders,
      :total_violations
    ])
  end
end
