defmodule WhoOwnsWhat.PromExPlugin do
  use PromEx.Plugin

  @property_show_event [:who_owns_what, :property, :show]
  @owner_group_show_event [:who_owns_what, :owner_group, :show]

  @impl true
  def event_metrics(_opts) do
    [
      property_general_event_metrics(),
      owner_group_general_event_metrics()
    ]
  end

  defp owner_group_general_event_metrics do
    Event.build(
      :who_owns_what_owner_group_general_event_metrics,
      [
        counter(
          @owner_group_show_event ++ [:count],
          event_name: @owner_group_show_event,
          description: "The number of owner group show events that have occurred",
          tags: [:name],
          tag_values: &get_owner_group_tag_values/1
        )
      ]
    )
  end

  defp property_general_event_metrics do
    Event.build(
      :who_owns_what_property_general_event_metrics,
      [
        counter(
          @property_show_event ++ [:count],
          event_name: @property_show_event,
          description: "The number of property show events that have occurred",
          tags: [:zip_code, :owner_group_name],
          tag_values: &get_property_tag_values/1
        )
      ]
    )
  end

  defp get_property_tag_values(%{property: property}) do
    %{zip_code: property.geo_zip_code, owner_group_name: property.owner_group.name}
  end

  defp get_owner_group_tag_values(%{owner_group: owner_group}) do
    %{name: owner_group.name}
  end
end
