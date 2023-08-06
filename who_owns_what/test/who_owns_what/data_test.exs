defmodule WhoOwnsWhat.DataTest do
  use WhoOwnsWhat.DataCase

  alias WhoOwnsWhat.Data

  describe "properties" do
    alias WhoOwnsWhat.Data.Property

    import WhoOwnsWhat.DataFixtures

    @invalid_attrs %{
      c_a_class: nil,
      c_a_total: nil,
      calculated_owner_occupied: nil,
      geo_alder: nil,
      geo_zip_code: nil,
      house_number_high: nil,
      house_number_low: nil,
      house_number_suffix: nil,
      land_use_gp: nil,
      number_units: nil,
      owner_address: nil,
      owner_city_state: nil,
      owner_name_1: nil,
      owner_name_2: nil,
      owner_name_3: nil,
      owner_occupied: nil,
      owner_zip_code: nil,
      street: nil,
      street_direction: nil,
      street_type: nil,
      taxkey: nil
    }

    test "list_properties/0 returns all properties" do
      property = property_fixture()
      assert Data.list_properties() == [property]
    end

    test "get_property!/1 returns the property with given id" do
      property = property_fixture()
      assert Data.get_property!(property.id) == property
    end

    test "create_property/1 with valid data creates a property" do
      valid_attrs = %{
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
      }

      assert {:ok, %Property{} = property} = Data.create_property(valid_attrs)
      assert property.c_a_class == "some c_a_class"
      assert property.c_a_total == 42
      assert property.calculated_owner_occupied == true
      assert property.geo_alder == "some geo_alder"
      assert property.geo_zip_code == "some geo_zip_code"
      assert property.house_number_high == 42
      assert property.house_number_low == 42
      assert property.house_number_suffix == "some house_number_suffix"
      assert property.land_use_gp == "some land_use_gp"
      assert property.number_units == 42
      assert property.owner_address == "some owner_address"
      assert property.owner_city_state == "some owner_city_state"
      assert property.owner_name_1 == "some owner_name_1"
      assert property.owner_name_2 == "some owner_name_2"
      assert property.owner_name_3 == "some owner_name_3"
      assert property.owner_occupied == true
      assert property.owner_zip_code == "some owner_zip_code"
      assert property.street == "some street"
      assert property.street_direction == "some street_direction"
      assert property.street_type == "some street_type"
      assert property.taxkey == "some taxkey"
    end

    test "create_property/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_property(@invalid_attrs)
    end

    test "update_property/2 with valid data updates the property" do
      property = property_fixture()

      update_attrs = %{
        c_a_class: "some updated c_a_class",
        c_a_total: 43,
        calculated_owner_occupied: false,
        geo_alder: "some updated geo_alder",
        geo_zip_code: "some updated geo_zip_code",
        house_number_high: 43,
        house_number_low: 43,
        house_number_suffix: "some updated house_number_suffix",
        land_use_gp: "some updated land_use_gp",
        number_units: 43,
        owner_address: "some updated owner_address",
        owner_city_state: "some updated owner_city_state",
        owner_name_1: "some updated owner_name_1",
        owner_name_2: "some updated owner_name_2",
        owner_name_3: "some updated owner_name_3",
        owner_occupied: false,
        owner_zip_code: "some updated owner_zip_code",
        street: "some updated street",
        street_direction: "some updated street_direction",
        street_type: "some updated street_type",
        taxkey: "some updated taxkey"
      }

      assert {:ok, %Property{} = property} = Data.update_property(property, update_attrs)
      assert property.c_a_class == "some updated c_a_class"
      assert property.c_a_total == 43
      assert property.calculated_owner_occupied == false
      assert property.geo_alder == "some updated geo_alder"
      assert property.geo_zip_code == "some updated geo_zip_code"
      assert property.house_number_high == 43
      assert property.house_number_low == 43
      assert property.house_number_suffix == "some updated house_number_suffix"
      assert property.land_use_gp == "some updated land_use_gp"
      assert property.number_units == 43
      assert property.owner_address == "some updated owner_address"
      assert property.owner_city_state == "some updated owner_city_state"
      assert property.owner_name_1 == "some updated owner_name_1"
      assert property.owner_name_2 == "some updated owner_name_2"
      assert property.owner_name_3 == "some updated owner_name_3"
      assert property.owner_occupied == false
      assert property.owner_zip_code == "some updated owner_zip_code"
      assert property.street == "some updated street"
      assert property.street_direction == "some updated street_direction"
      assert property.street_type == "some updated street_type"
      assert property.taxkey == "some updated taxkey"
    end

    test "update_property/2 with invalid data returns error changeset" do
      property = property_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_property(property, @invalid_attrs)
      assert property == Data.get_property!(property.id)
    end

    test "delete_property/1 deletes the property" do
      property = property_fixture()
      assert {:ok, %Property{}} = Data.delete_property(property)
      assert_raise Ecto.NoResultsError, fn -> Data.get_property!(property.id) end
    end

    test "change_property/1 returns a property changeset" do
      property = property_fixture()
      assert %Ecto.Changeset{} = Data.change_property(property)
    end
  end

  describe "owner_groups_properties" do
    alias WhoOwnsWhat.Data.OwnerGroupProperty

    import WhoOwnsWhat.DataFixtures

    @invalid_attrs %{owner_group: nil, taxkey: nil}

    test "list_owner_groups_properties/0 returns all owner_groups_properties" do
      owner_group_property = owner_group_property_fixture()
      assert Data.list_owner_groups_properties() == [owner_group_property]
    end

    test "get_owner_group_property!/1 returns the owner_group_property with given id" do
      owner_group_property = owner_group_property_fixture()
      assert Data.get_owner_group_property!(owner_group_property.id) == owner_group_property
    end

    test "create_owner_group_property/1 with valid data creates a owner_group_property" do
      valid_attrs = %{owner_group: "some owner_group", taxkey: "some taxkey"}

      assert {:ok, %OwnerGroupProperty{} = owner_group_property} =
               Data.create_owner_group_property(valid_attrs)

      assert owner_group_property.owner_group == "some owner_group"
      assert owner_group_property.taxkey == "some taxkey"
    end

    test "create_owner_group_property/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_owner_group_property(@invalid_attrs)
    end

    test "update_owner_group_property/2 with valid data updates the owner_group_property" do
      owner_group_property = owner_group_property_fixture()
      update_attrs = %{owner_group: "some updated owner_group", taxkey: "some updated taxkey"}

      assert {:ok, %OwnerGroupProperty{} = owner_group_property} =
               Data.update_owner_group_property(owner_group_property, update_attrs)

      assert owner_group_property.owner_group == "some updated owner_group"
      assert owner_group_property.taxkey == "some updated taxkey"
    end

    test "update_owner_group_property/2 with invalid data returns error changeset" do
      owner_group_property = owner_group_property_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Data.update_owner_group_property(owner_group_property, @invalid_attrs)

      assert owner_group_property == Data.get_owner_group_property!(owner_group_property.id)
    end

    test "delete_owner_group_property/1 deletes the owner_group_property" do
      owner_group_property = owner_group_property_fixture()
      assert {:ok, %OwnerGroupProperty{}} = Data.delete_owner_group_property(owner_group_property)

      assert_raise Ecto.NoResultsError, fn ->
        Data.get_owner_group_property!(owner_group_property.id)
      end
    end

    test "change_owner_group_property/1 returns a owner_group_property changeset" do
      owner_group_property = owner_group_property_fixture()
      assert %Ecto.Changeset{} = Data.change_owner_group_property(owner_group_property)
    end
  end
end
