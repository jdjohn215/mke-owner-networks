defmodule WhoOwnsWhatWeb.OwnerGroupLive.SearchComponent do
  use WhoOwnsWhatWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      assign_new(socket, :owner_groups, fn -> [] end)
      |> assign_new(:owner_query, fn -> "" end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.search_input
        target={@myself}
        text_value={@owner_query}
        event="do-search-owner"
        name="Owner Group"
      />
      <.results owner_groups={@owner_groups} />
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
        phx-target={@target}
        phx-keyup={@event}
        phx-debounce="100"
        type="text"
        class=""
        placeholder={"Search by #{@name}"}
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
      <:col :let={owner_group} label="Total Properties"><%= owner_group.number_properties %></:col>
      <:col :let={owner_group} label="Total Units"><%= owner_group.number_units %></:col>
    </.table>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:owner_groups, search_owner_groups(assigns.owner_query, []))}
  end

  @impl true
  def handle_event("do-search-owner", %{"value" => value}, socket) do
    params = %{owner_query: value}

    {:noreply,
     socket
     |> push_patch(to: ~p"/owner_groups?#{params}")
     |> assign(:owner_query, value)}
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
