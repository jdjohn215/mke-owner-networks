defmodule WhoOwnsWhat.Data.Property do
  use Ecto.Schema
  import Ecto.Changeset
  alias WhoOwnsWhat.Data.OwnerGroupProperty

  schema "properties" do
    field :c_a_class, :string
    field :c_a_total, :integer
    field :calculated_owner_occupied, :boolean, default: false
    field :geo_alder, :string
    field :geo_zip_code, :string
    field :house_number_high, :integer
    field :house_number_low, :integer
    field :house_number_suffix, :string
    field :land_use_gp, :string
    field :number_units, :integer
    field :owner_address, :string
    field :owner_city_state, :string
    field :owner_name_1, :string
    field :owner_name_2, :string
    field :owner_name_3, :string
    field :owner_occupied, :boolean, default: false
    field :owner_zip_code, :string
    field :street, :string
    field :street_direction, :string
    field :street_type, :string
    field :taxkey, :string
    field :wdfi_address, :string
    field :zoning, :string
    field :dns_covered_days, :integer
    field :dns_covered_unit_years, :float
    field :total_dns_orders, :integer
    field :total_dns_violations, :integer
    field :ownership_dns_orders, :integer
    field :ownership_dns_violations, :integer
    field :eviction_filings, :integer
    field :eviction_orders, :integer
    field :convey_date, :date
    field :latitude, :float
    field :longitude, :float

    timestamps()

    belongs_to :owner_groups_properties, OwnerGroupProperty,
      foreign_key: :taxkey,
      references: :taxkey,
      define_field: false

    has_one :owner_group,
      through: [:owner_groups_properties, :owner_group]
  end

  @doc false
  def changeset(property, attrs) do
    property
    |> cast(attrs, [
      :taxkey,
      :house_number_low,
      :house_number_high,
      :house_number_suffix,
      :street_direction,
      :street,
      :street_type,
      :c_a_class,
      :land_use_gp,
      :c_a_total,
      :number_units,
      :owner_name_1,
      :owner_name_2,
      :owner_name_3,
      :owner_address,
      :owner_city_state,
      :owner_zip_code,
      :geo_zip_code,
      :calculated_owner_occupied,
      :owner_occupied,
      :eviction_filings,
      :eviction_orders,
      :geo_alder,
      :zoning
    ])
    |> validate_required([
      :taxkey,
      :house_number_low,
      :house_number_high,
      :house_number_suffix,
      :street_direction,
      :street,
      :street_type,
      :c_a_class,
      :land_use_gp,
      :c_a_total,
      :number_units,
      :owner_name_1,
      :owner_name_2,
      :owner_name_3,
      :owner_address,
      :owner_city_state,
      :owner_zip_code,
      :geo_zip_code,
      :calculated_owner_occupied,
      :owner_occupied,
      :geo_alder,
      :zoning
    ])
  end

  def address_without_zip_code(property = %__MODULE__{}) do
    if property.house_number_low != property.house_number_high do
      "#{property.house_number_low}-#{property.house_number_high} #{property.street_direction} #{property.street} #{property.street_type}"
    else
      "#{property.house_number_low} #{property.street_direction} #{property.street} #{property.street_type}"
    end
  end

  def address(property = %__MODULE__{}) do
    zip_code =
      if property.geo_zip_code do
        String.slice(property.geo_zip_code, 0, 5)
      else
        nil
      end

    if property.house_number_low != property.house_number_high do
      "#{property.house_number_low}-#{property.house_number_high} #{property.street_direction} #{property.street} #{property.street_type}, #{zip_code}"
    else
      "#{property.house_number_low} #{property.street_direction} #{property.street} #{property.street_type}, #{zip_code}"
    end
  end
end
