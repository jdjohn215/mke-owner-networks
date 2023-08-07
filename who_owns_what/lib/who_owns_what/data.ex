defmodule WhoOwnsWhat.Data do
  alias WhoOwnsWhat.Repo
  alias WhoOwnsWhat.Data.Property
  alias WhoOwnsWhat.Data.PropertyFts
  alias WhoOwnsWhat.Data.OwnerGroupProperty
  alias WhoOwnsWhat.Data.OwnerGroup

  import Ecto.Query, only: [from: 2]

  def format_query(query) do
    q =
      String.split(query, " ")
      |> Enum.join("%")

    "%#{q}%"
  end

  def search_owner_groups(owner_query) do
    query =
      if owner_query != "" do
        formatted_query = format_query(owner_query)

        fts_query =
          from(pf in PropertyFts,
            where: fragment("? LIKE ?", pf.owner_group_name, ^formatted_query),
            # or_where: fragment("? LIKE ?", pf.owner_name_1, ^formatted_query),
            group_by: pf.owner_group_name
          )

        from(og in OwnerGroup,
          join: pf in subquery(fts_query),
          on: pf.owner_group_name == og.name,
          order_by: [desc: og.number_units],
          limit: 1000
        )
      else
        from(og in OwnerGroup,
          order_by: [desc: :number_units],
          limit: 100
        )
      end

    Repo.all(query)
  end

  def search_properties(owner_query, address_query) do
    query =
      from(pf in PropertyFts,
        join: p in Property,
        on: p.taxkey == pf.taxkey,
        select: %{p | owner_group: %OwnerGroup{name: pf.owner_group_name}},
        order_by: [asc: :rank],
        limit: 1000
      )

    query =
      if owner_query != "" do
        formatted_query = format_query(owner_query)

        from([pf, p] in query,
          where: fragment("? LIKE ?", pf.owner_group_name, ^formatted_query),
          or_where: fragment("? LIKE ?", pf.owner_name_1, ^formatted_query)
        )
      else
        query
      end

    query =
      if address_query != "" do
        formatted_query = format_query(address_query)

        from(p in query,
          where: fragment("full_address LIKE ?", ^formatted_query)
        )
      else
        query
      end

    query
    |> Repo.all()
    |> Repo.preload(:owner_group)
  end

  @doc """
  Returns the list of properties.

  ## Examples

      iex> list_properties()
      [%Property{}, ...]

  """
  def list_properties do
    Repo.all(Property)
  end

  def list_properties_by_owner_group_name(name) do
    from(
      ogp in OwnerGroupProperty,
      join: p in Property,
      on: p.taxkey == ogp.taxkey,
      select: p,
      where: ogp.owner_group_name == ^name
    )
    |> Repo.all()
  end

  def get_property_by_taxkey!(taxkey) do
    Repo.get_by!(Property, taxkey: taxkey)
    |> Repo.preload(:owner_group)
  end

  def get_owner_group_by_name(name) do
    from(og in OwnerGroup,
      where: og.name == ^name,
      limit: 1
    )
    |> Repo.one!()
  end
end
