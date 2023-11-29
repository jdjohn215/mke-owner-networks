defmodule WhoOwnsWhatWeb.HomeLive.About do
  use WhoOwnsWhatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "About | Milwaukee Property Ownership Network Project")
    {:ok, socket}
  end
end
