defmodule WhoOwnsWhatWeb.OwnerGroupPropertyLive.Index do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data
  alias WhoOwnsWhat.Data.OwnerGroupProperty

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :owner_groups_properties, Data.list_owner_groups_properties())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Owner groups properties")
    |> assign(:owner_group_property, nil)
  end
end
