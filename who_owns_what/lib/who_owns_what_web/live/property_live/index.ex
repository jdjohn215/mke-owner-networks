defmodule WhoOwnsWhatWeb.PropertyLive.Index do
  use WhoOwnsWhatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Listing Properties")
    {:ok, stream(socket, :properties, [])}
  end
end
