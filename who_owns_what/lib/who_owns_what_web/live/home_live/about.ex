defmodule WhoOwnsWhatWeb.HomeLive.About do
  use WhoOwnsWhatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "About | The Milwaukee Landlord Network Project")
    {:ok, socket}
  end
end
