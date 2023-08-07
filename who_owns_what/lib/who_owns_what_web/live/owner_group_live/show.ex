defmodule WhoOwnsWhatWeb.OwnerGroupLive.Show do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => name}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:owner_group, Data.get_owner_group_by_name(name))
     |> assign(:properties, Data.list_properties_by_owner_group_name(name))}
  end

  defp page_title(:show), do: "Show Owner group"
end
