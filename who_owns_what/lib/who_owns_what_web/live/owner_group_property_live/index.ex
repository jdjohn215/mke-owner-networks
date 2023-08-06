defmodule WhoOwnsWhatWeb.OwnerGroupPropertyLive.Index do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Listing Owner Groups")
    {:ok, stream(socket, :owner_groups, Data.list_owner_groups_properties())}
  end
end
