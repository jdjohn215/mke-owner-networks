defmodule WhoOwnsWhat.DataFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WhoOwnsWhat.Data` context.
  """

  @doc """
  Generate a property.
  """
  def property_fixture(attrs \\ %{}) do
    {:ok, property} =
      attrs
      |> Enum.into(%{
        c_a_class: "some c_a_class",
        c_a_total: 42,
        calculated_owner_occupied: true,
        geo_alder: "some geo_alder",
        geo_zip_code: "some geo_zip_code",
        house_number_high: 42,
        house_number_low: 42,
        house_number_suffix: "some house_number_suffix",
        land_use_gp: "some land_use_gp",
        number_units: 42,
        owner_address: "some owner_address",
        owner_city_state: "some owner_city_state",
        owner_name_1: "some owner_name_1",
        owner_name_2: "some owner_name_2",
        owner_name_3: "some owner_name_3",
        owner_occupied: true,
        owner_zip_code: "some owner_zip_code",
        street: "some street",
        street_direction: "some street_direction",
        street_type: "some street_type",
        taxkey: "some taxkey"
      })
      |> WhoOwnsWhat.Data.create_property()

    property
  end

  @doc """
  Generate a owner_group_property.
  """
  def owner_group_property_fixture(attrs \\ %{}) do
    {:ok, owner_group_property} =
      attrs
      |> Enum.into(%{
        owner_group: "some owner_group",
        taxkey: "some taxkey"
      })
      |> WhoOwnsWhat.Data.create_owner_group_property()

    owner_group_property
  end
end
