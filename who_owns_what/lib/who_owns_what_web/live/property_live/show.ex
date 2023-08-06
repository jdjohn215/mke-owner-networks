defmodule WhoOwnsWhatWeb.PropertyLive.Show do
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
     |> assign(:property, Data.get_property!(id))}
  end

  defp page_title(:show), do: "Show Property"
end
