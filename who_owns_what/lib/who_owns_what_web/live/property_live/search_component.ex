defmodule WhoOwnsWhatWeb.PropertyLive.SearchComponent do
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
      <.search_input
        phx-target={@myself}
        placeholder_name="Address"
        phx-keyup="do-search-address"
        phx-debounce="200"
      />
      <.results properties={@properties} />
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

  attr :properties, :list, required: true

  def results(assigns) do
    ~H"""
    <div :if={@properties == []} id="option-none">
      No Results
    </div>

    <table class="" id="properties">
      <thead>
        <tr>
          <th>Address</th>
          <th>Owner Group</th>
          <th>Owner Name</th>
        </tr>
      </thead>
      <tbody>
        <.result_item :for={property <- @properties} property={property} />
      </tbody>
    </table>
    """
  end

  attr :property, :map, required: true

  def result_item(assigns) do
    ~H"""
    <tr class="" id={"option-#{@property.id}"}>
      <td>
        <.link navigate={~p"/properties/#{@property.id}"} id={"property-#{@property.id}"}>
          <%= WhoOwnsWhat.Data.Property.address(@property) %>
        </.link>
      </td>
      <td>
        <.link
          navigate={~p"/owner_group/#{@property.owner_group.name}"}
          id={"property-#{@property.id}"}
        >
          <%= @property.owner_group.name %>
        </.link>
      </td>
      <td>
        <%= @property.owner_name_1 %>
      </td>
    </tr>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:properties, fn -> [] end)
     |> assign_new(:owner_query, fn -> "" end)
     |> assign_new(:address_query, fn -> "" end)}
  end

  @impl true
  def handle_event("do-search-owner", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:owner_query, value)
     |> assign(
       :properties,
       search_properties(value, socket.assigns.address_query, socket.assigns.properties)
     )}
  end

  @impl true
  def handle_event("do-search-address", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:address_query, value)
     |> assign(
       :properties,
       search_properties(socket.assigns.owner_query, value, socket.assigns.properties)
     )}
  end

  defp search_properties(owner_query, address_query, default)
       when is_binary(owner_query) and is_binary(address_query) do
    try do
      WhoOwnsWhat.Data.search_properties(owner_query, address_query)
    rescue
      Exqlite.Error ->
        default
    end
  end

  defp search_properties(_, _, default), do: default
end
