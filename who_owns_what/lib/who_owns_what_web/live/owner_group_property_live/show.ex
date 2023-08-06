defmodule WhoOwnsWhatWeb.OwnerGroupPropertyLive.Show do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:owner_group_property, Data.get_owner_group_property_by_name(id))
     |> assign(:properties, Data.list_properties_by_owner_group_name(id))
     |> assign_summary()}
  end

  def assign_summary(socket) do
    total_unit_count = Enum.map(socket.assigns.properties, fn(property) ->
      property.number_units
    end)
    |> Enum.sum()

    total_property_count = Enum.count(socket.assigns.properties)

    assign(socket, :total_property_count, total_property_count)
    |> assign(:total_unit_count, total_unit_count)
  end

  defp page_title(:show), do: "Show Owner group property"
  defp page_title(:edit), do: "Edit Owner group property"
end
