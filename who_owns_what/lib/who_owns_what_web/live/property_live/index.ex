defmodule WhoOwnsWhatWeb.PropertyLive.Index do
  use WhoOwnsWhatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Listing Properties")
    {:ok, stream(socket, :properties, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    owner_query = Map.get(params, "owner_query", "")
    owner_group_query = Map.get(params, "owner_group_query", "")
    address_query = Map.get(params, "address_query", "")

    socket =
      assign(socket, :owner_query, owner_query)
      |> assign(:owner_group_query, owner_group_query)
      |> assign(:address_query, address_query)

    {:noreply, stream(socket, :properties, [])}
  end
end
