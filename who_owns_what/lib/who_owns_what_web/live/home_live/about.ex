defmodule WhoOwnsWhatWeb.HomeLive.About do
  use WhoOwnsWhatWeb, :live_view
  alias WhoOwnsWhat.Data.Import

  @impl true
  def mount(_params, _session, socket) do
    overall_summary_data = Import.overall_summary_data()

    socket =
      assign(socket, :page_title, "About | Milwaukee Property Ownership Network Project")
      |> assign(:evict_start, Map.fetch!(overall_summary_data, "evict_start"))
      |> assign(:dns_start, Map.fetch!(overall_summary_data, "dns_start"))

    {:ok, socket}
  end
end
