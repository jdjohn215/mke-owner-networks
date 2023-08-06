defmodule WhoOwnsWhatWeb.OwnerGroupPropertyLiveTest do
  use WhoOwnsWhatWeb.ConnCase

  import Phoenix.LiveViewTest
  import WhoOwnsWhat.DataFixtures

  @create_attrs %{name: "some name", taxkey: "some taxkey"}
  @update_attrs %{name: "some updated name", taxkey: "some updated taxkey"}
  @invalid_attrs %{name: nil, taxkey: nil}

  defp create_owner_group_property(_) do
    owner_group_property = owner_group_property_fixture()
    %{owner_group_property: owner_group_property}
  end

  describe "Index" do
    setup [:create_owner_group_property]

    test "lists all owner_groups_properties", %{
      conn: conn,
      owner_group_property: owner_group_property
    } do
      {:ok, _index_live, html} = live(conn, ~p"/owner_groups_properties")

      assert html =~ "Listing Owner groups properties"
      assert html =~ owner_group_property.name
    end

    test "saves new owner_group_property", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/owner_groups_properties")

      assert index_live |> element("a", "New Owner group property") |> render_click() =~
               "New Owner group property"

      assert_patch(index_live, ~p"/owner_groups_properties/new")

      assert index_live
             |> form("#owner_group_property-form", owner_group_property: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#owner_group_property-form", owner_group_property: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/owner_groups_properties")

      html = render(index_live)
      assert html =~ "Owner group property created successfully"
      assert html =~ "some name"
    end

    test "updates owner_group_property in listing", %{
      conn: conn,
      owner_group_property: owner_group_property
    } do
      {:ok, index_live, _html} = live(conn, ~p"/owner_groups_properties")

      assert index_live
             |> element("#owner_groups_properties-#{owner_group_property.id} a", "Edit")
             |> render_click() =~
               "Edit Owner group property"

      assert_patch(index_live, ~p"/owner_groups_properties/#{owner_group_property}/edit")

      assert index_live
             |> form("#owner_group_property-form", owner_group_property: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#owner_group_property-form", owner_group_property: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/owner_groups_properties")

      html = render(index_live)
      assert html =~ "Owner group property updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes owner_group_property in listing", %{
      conn: conn,
      owner_group_property: owner_group_property
    } do
      {:ok, index_live, _html} = live(conn, ~p"/owner_groups_properties")

      assert index_live
             |> element("#owner_groups_properties-#{owner_group_property.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#owner_groups_properties-#{owner_group_property.id}")
    end
  end

  describe "Show" do
    setup [:create_owner_group_property]

    test "displays owner_group_property", %{
      conn: conn,
      owner_group_property: owner_group_property
    } do
      {:ok, _show_live, html} = live(conn, ~p"/owner_groups_properties/#{owner_group_property}")

      assert html =~ "Show Owner group property"
      assert html =~ owner_group_property.name
    end

    test "updates owner_group_property within modal", %{
      conn: conn,
      owner_group_property: owner_group_property
    } do
      {:ok, show_live, _html} = live(conn, ~p"/owner_groups_properties/#{owner_group_property}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Owner group property"

      assert_patch(show_live, ~p"/owner_groups_properties/#{owner_group_property}/show/edit")

      assert show_live
             |> form("#owner_group_property-form", owner_group_property: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#owner_group_property-form", owner_group_property: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/owner_groups_properties/#{owner_group_property}")

      html = render(show_live)
      assert html =~ "Owner group property updated successfully"
      assert html =~ "some updated name"
    end
  end
end
