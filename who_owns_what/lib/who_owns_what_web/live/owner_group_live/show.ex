defmodule WhoOwnsWhatWeb.OwnerGroupLive.Show do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data

  @boundary_geojson "priv/data/boundary.geojson" |> File.read!()

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => name}, _, socket) do
    owner_group = Data.get_owner_group_by_name(name)
    properties = Data.list_properties_by_owner_group_name(name)
    first_property = hd(properties)

    :telemetry.execute([:who_owns_what, :owner_group, :show], %{count: 1}, %{
      owner_group: owner_group
    })

    has_multiple_unique_owner_names =
      Enum.any?(properties, fn property ->
        property.owner_name_1 != first_property.owner_name_1
      end)

    geojson = properties_to_geojson(properties)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:owner_group, owner_group)
     |> assign(:show_network_graph, has_multiple_unique_owner_names)
     |> assign(:properties, properties)
     |> assign(:geojson, geojson)
     |> assign(:boundary_geojson, @boundary_geojson)
     |> assign_groups(properties)}
  end

  defp page_title(:show), do: "Show Owner Group"

  defp properties_to_geojson(properties) do
    features =
      properties
      |> Enum.filter(&(&1.latitude && &1.longitude))
      |> Enum.map(fn property ->
        %{
          type: "Feature",
          geometry: %{
            type: "Point",
            coordinates: [property.longitude, property.latitude]
          },
          properties: %{
            taxkey: property.taxkey,
            address: Data.Property.address(property),
            units: property.number_units
          }
        }
      end)

    Jason.encode!(%{type: "FeatureCollection", features: features})
  end

  defp assign_groups(socket, properties) do
    groups =
      Enum.reduce(properties, %{}, fn property, map ->
        Map.update(
          map,
          property.geo_alder,
          %{
            district: property.geo_alder,
            number_units: property.number_units,
            number_properties: 1
          },
          fn map ->
            Map.update!(map, :number_units, &(&1 + property.number_units))
            |> Map.update!(:number_properties, &(&1 + 1))
          end
        )
      end)
      |> Map.values()

    assign(socket, :alder_groups, groups)
  end
end
