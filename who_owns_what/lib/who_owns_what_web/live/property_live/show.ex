defmodule WhoOwnsWhatWeb.PropertyLive.Show do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data
  alias WhoOwnsWhat.Data.Import

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => taxkey}, _, socket) do
    property = Data.get_property_by_taxkey!(taxkey)

    overall_summary_data = Import.overall_summary_data()
    dns_data_start_date = Map.fetch!(overall_summary_data, "dns_start")
    eviction_data_start_date = Map.fetch!(overall_summary_data, "evict_start")

    dns_data_date =
      if is_nil(property.convey_date) ||
           Date.compare(property.convey_date, dns_data_start_date) == :lt do
        dns_data_start_date
      else
        property.convey_date
      end

    eviction_data_date =
      if is_nil(property.convey_date) ||
           Date.compare(property.convey_date, eviction_data_start_date) == :lt do
        eviction_data_start_date
      else
        property.convey_date
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:property, property)
     |> assign(:dns_data_date, dns_data_date)
     |> assign(:eviction_data_date, eviction_data_date)}
  end

  defp page_title(:show), do: "Show Property"
end
