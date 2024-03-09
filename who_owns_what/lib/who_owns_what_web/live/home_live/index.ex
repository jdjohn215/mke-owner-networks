defmodule WhoOwnsWhatWeb.HomeLive.Index do
  use WhoOwnsWhatWeb, :live_view
  alias WhoOwnsWhat.Data.Import

  @impl true
  def mount(_params, _session, socket) do
    overall_summary_data = Import.overall_summary_data()

    socket =
      assign(socket, :page_title, "Milwaukee Property Ownership Network Project")
      |> assign(:total_parcels, Map.fetch!(overall_summary_data, "total_parcels"))
      |> assign(:total_mprop_names, Map.fetch!(overall_summary_data, "total_mprop_names"))
      |> assign(:total_mprop_addresses, Map.fetch!(overall_summary_data, "total_mprop_addresses"))
      |> assign(:total_networks, Map.fetch!(overall_summary_data, "total_networks"))
      |> assign(
        :pct_networks_single_parcel,
        Map.fetch!(overall_summary_data, "pct_networks_single_parcel")
      )
      |> assign(
        :pct_networks_multiple_names,
        Map.fetch!(overall_summary_data, "pct_networks_multiple_names")
      )
      |> assign(
        :pct_parcels_multiple_name_owner,
        Map.fetch!(overall_summary_data, "pct_parcels_multiple_name_owner")
      )
      |> assign(:mprop_updated, Map.fetch!(overall_summary_data, "mprop_updated"))
      |> assign(:workflow_updated, Map.fetch!(overall_summary_data, "workflow_updated"))
      |> assign(:wdfi_updated, Map.fetch!(overall_summary_data, "wdfi_updated"))
      |> assign(:evict_start, Map.fetch!(overall_summary_data, "evict_start"))
      |> assign(:evict_end, Map.fetch!(overall_summary_data, "evict_end"))
      |> assign(:dns_start, Map.fetch!(overall_summary_data, "dns_start"))
      |> assign(:dns_end, Map.fetch!(overall_summary_data, "dns_end"))

    {:ok, socket}
  end
end
