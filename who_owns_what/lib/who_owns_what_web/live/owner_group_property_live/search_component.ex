defmodule WhoOwnsWhatWeb.OwnerGroupPropertyLive.SearchComponent do
  use WhoOwnsWhatWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.search_input
        phx-target={@myself}
        placeholder_name="Owner Group"
        phx-keyup="do-search-owner"
        phx-debounce="200"
      />
      <.results owner_groups={@owner_groups} />
    </div>
    """
  end

  attr :rest, :global
  attr :placeholder_name, :string, required: true

  def search_input(assigns) do
    ~H"""
    <div>
      <input
        {@rest}
        type="text"
        class=""
        placeholder={"Search by #{@placeholder_name}"}
        aria-expanded="false"
        aria-controls="options"
      />
    </div>
    """
  end

  attr :owner_groups, :list, required: true

  def results(assigns) do
    ~H"""
    <div :if={@owner_groups == []} id="option-none">
      No Results
    </div>

    <.table id="owner_groups" rows={@owner_groups}>
      <:col :let={owner_group} label="Owner Group">
        <.good_link navigate={~p"/owner_groups/#{owner_group.name}"}>
          <%= owner_group.name %>
        </.good_link>
      </:col>
      <:col :let={owner_group} label="Total Properties"><%= owner_group.total_properties %></:col>
      <:col :let={owner_group} label="Total Units"><%= owner_group.total_units %></:col>
    </.table>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:owner_groups, fn -> [] end)
     |> assign_new(:owner_query, fn -> "" end)}
  end

  @impl true
  def handle_event("do-search-owner", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:owner_query, value)
     |> assign(
       :owner_groups,
       search_owner_groups(value, socket.assigns.owner_groups)
     )}
  end

  defp search_owner_groups(owner_query, default) when is_binary(owner_query) do
    try do
      WhoOwnsWhat.Data.search_owner_groups(owner_query)
    rescue
      Exqlite.Error ->
        default
    end
  end

  defp search_owner_groups(_, default), do: default
end
