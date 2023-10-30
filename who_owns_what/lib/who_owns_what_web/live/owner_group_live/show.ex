defmodule WhoOwnsWhatWeb.OwnerGroupLive.Show do
  use WhoOwnsWhatWeb, :live_view

  alias WhoOwnsWhat.Data

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => name}, _, socket) do
    properties = Data.list_properties_by_owner_group_name(name)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:owner_group, Data.get_owner_group_by_name(name))
     |> assign(:properties, properties)
     |> assign(:svg, nil)
     |> assign_graphs(properties)}
  end

  @impl true
  def handle_info({port, {:data, svg}}, socket) when is_port(port) do
    Port.close(port)

    svg =
      String.replace(svg, ~r/(width|height)="\d+pt"/, "")
      |> String.replace(~r/<!--.*-->/, "")

    socket =
      assign(socket, :svg_port, nil)
      |> assign(:svg, svg)

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Owner Group"

  defp assign_graphs(socket, properties) do
    graph =
      Enum.reduce(properties, Graph.new(type: :undirected), fn property, graph ->
        graph = Graph.add_edge(graph, property.owner_name_1, property.owner_address)

        if property.wdfi_address do
          Graph.add_edge(graph, property.owner_name_1, property.wdfi_address)
        else
          graph
        end
      end)

    {:ok, dot} = Graph.Serializers.DOT.serialize(graph)
    port = Port.open({:spawn, "dot -Grankdir=LR -Tsvg"}, [:binary])
    Port.command(port, dot)

    assign(socket, :graph, graph)
    |> assign(:svg_port, port)
  end
end
