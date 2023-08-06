defmodule WhoOwnsWhatWeb.PropertyLiveTest do
  use WhoOwnsWhatWeb.ConnCase

  import Phoenix.LiveViewTest
  import WhoOwnsWhat.DataFixtures

  @create_attrs %{full_address: "some full_address", owner_group: "some owner_group"}
  @update_attrs %{
    full_address: "some updated full_address",
    owner_group: "some updated owner_group"
  }
  @invalid_attrs %{full_address: nil, owner_group: nil}

  defp create_property(_) do
    property = property_fixture()
    %{property: property}
  end

  describe "Index" do
    setup [:create_property]

    test "lists all properties", %{conn: conn, property: property} do
      {:ok, _index_live, html} = live(conn, ~p"/properties")

      assert html =~ "Listing Properties"
      assert html =~ property.full_address
    end

    test "saves new property", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/properties")

      assert index_live |> element("a", "New Property") |> render_click() =~
               "New Property"

      assert_patch(index_live, ~p"/properties/new")

      assert index_live
             |> form("#property-form", property: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#property-form", property: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/properties")

      html = render(index_live)
      assert html =~ "Property created successfully"
      assert html =~ "some full_address"
    end

    test "updates property in listing", %{conn: conn, property: property} do
      {:ok, index_live, _html} = live(conn, ~p"/properties")

      assert index_live |> element("#properties-#{property.id} a", "Edit") |> render_click() =~
               "Edit Property"

      assert_patch(index_live, ~p"/properties/#{property}/edit")

      assert index_live
             |> form("#property-form", property: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#property-form", property: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/properties")

      html = render(index_live)
      assert html =~ "Property updated successfully"
      assert html =~ "some updated full_address"
    end

    test "deletes property in listing", %{conn: conn, property: property} do
      {:ok, index_live, _html} = live(conn, ~p"/properties")

      assert index_live |> element("#properties-#{property.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#properties-#{property.id}")
    end
  end

  describe "Show" do
    setup [:create_property]

    test "displays property", %{conn: conn, property: property} do
      {:ok, _show_live, html} = live(conn, ~p"/properties/#{property}")

      assert html =~ "Show Property"
      assert html =~ property.full_address
    end

    test "updates property within modal", %{conn: conn, property: property} do
      {:ok, show_live, _html} = live(conn, ~p"/properties/#{property}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Property"

      assert_patch(show_live, ~p"/properties/#{property}/show/edit")

      assert show_live
             |> form("#property-form", property: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#property-form", property: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/properties/#{property}")

      html = render(show_live)
      assert html =~ "Property updated successfully"
      assert html =~ "some updated full_address"
    end
  end
end
