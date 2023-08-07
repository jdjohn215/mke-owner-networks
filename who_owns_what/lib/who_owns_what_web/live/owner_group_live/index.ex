defmodule WhoOwnsWhatWeb.OwnerGroupLive.Index do
  use WhoOwnsWhatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Listing Owner Groups")
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    owner_query = Map.get(params, "owner_query", "")

    socket =
      assign(socket, :owner_query, owner_query)
      |> assign(:owner_groups, [])

    {:noreply, socket}
  end
end
