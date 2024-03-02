defmodule WhoOwnsWhatWeb.PropertyLive.SearchComponent do
  use WhoOwnsWhatWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      assign_new(socket, :properties, fn -> [] end)
      |> assign_new(:owner_query, fn -> "" end)
      |> assign_new(:owner_group_query, fn -> "" end)
      |> assign_new(:address_query, fn -> "" end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.search_input
        target={@myself}
        event="do-search-address"
        text_value={@address_query}
        name="Address"
      />
      <.search_input
        target={@myself}
        event="do-search-owner"
        text_value={@owner_query}
        name="Owner Name"
      />
      <.search_input
        target={@myself}
        event="do-search-owner-group"
        text_value={@owner_group_query}
        name="Owner Group Name"
      />
      <.results properties={@properties} />
    </div>
    """
  end

  attr :text_value, :string
  attr :name, :string, required: true
  attr :target, :any, required: true
  attr :event, :string, required: true

  def search_input(assigns) do
    ~H"""
    <div>
      <.input
        value={@text_value}
        name={@name}
        label={@name}
        phx-target={@target}
        phx-keyup={@event}
        phx-debounce="100"
        type="text"
        class=""
        aria-expanded="false"
        aria-controls="options"
      />
    </div>
    """
  end

  attr :properties, :list, required: true

  def results(assigns) do
    ~H"""
    <div :if={@properties == []} id="option-none">
      No Results
    </div>
    <.table id="properties" row_id={&"#{&1.id}"} rows={@properties}>
      <:col :let={property} label="Address">
        <.good_link navigate={~p"/properties/#{property.taxkey}"}>
          <%= WhoOwnsWhat.Data.Property.address(property) %>
        </.good_link>
      </:col>
      <:col :let={property} label="Owner Group">
        <.good_link navigate={~p"/owner_groups/#{property.owner_group.name}"}>
          <%= property.owner_group.name %>
        </.good_link>
      </:col>
      <:col :let={property} label="Owner Name" class="hidden sm:table-cell">
        <%= property.owner_name_1 %>
      </:col>
      <:col :let={property} label="Assessed Value" class="hidden md:table-cell">
        $<%= format_dollars(property.c_a_total) %>
      </:col>
    </.table>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      assign(socket, assigns)
      |> assign(
        :properties,
        search_properties(
          assigns.owner_query,
          assigns.owner_group_query,
          assigns.address_query,
          []
        )
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("do-search-owner", %{"value" => value}, socket) do
    params = %{
      address_query: socket.assigns.address_query,
      owner_group_query: socket.assigns.owner_group_query,
      owner_query: value
    }

    {:noreply,
     socket
     |> push_patch(to: ~p"/properties?#{params}")
     |> assign(:owner_query, value)}
  end

  @impl true
  def handle_event("do-search-owner-group", %{"value" => value}, socket) do
    params = %{
      address_query: socket.assigns.address_query,
      owner_group_query: value,
      owner_query: socket.assigns.owner_query
    }

    {:noreply,
     socket
     |> push_patch(to: ~p"/properties?#{params}")
     |> assign(:owner_group_query, value)}
  end

  @impl true
  def handle_event("do-search-address", %{"value" => value}, socket) do
    params = %{
      address_query: value,
      owner_group_query: socket.assigns.owner_group_query,
      owner_query: socket.assigns.owner_query
    }

    {:noreply,
     socket
     |> push_patch(to: ~p"/properties?#{params}")
     |> assign(:address_query, value)}
  end

  defp search_properties(owner_query, owner_group_query, address_query, default)
       when is_binary(owner_query) and is_binary(owner_group_query) and is_binary(address_query) do
    try do
      WhoOwnsWhat.Data.search_properties(owner_query, owner_group_query, address_query)
    rescue
      Exqlite.Error ->
        default
    end
  end

  defp search_properties(_, _, _, default), do: default
end
