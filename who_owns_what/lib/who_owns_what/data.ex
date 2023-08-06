defmodule WhoOwnsWhat.Data do
  alias WhoOwnsWhat.Repo
  alias WhoOwnsWhat.Data.Property
  alias WhoOwnsWhat.Data.PropertyFts
  alias WhoOwnsWhat.Data.OwnerGroupProperty

  import Ecto.Query, only: [from: 2]

  def format_query(query) do
    q =
      String.split(query, " ")
      |> Enum.join("%")

    "%#{q}%"
  end

  def search_owner_groups(owner_query) do
    query =
      from(pf in PropertyFts,
        join: p in Property,
        on: p.taxkey == pf.taxkey,
        join: ogp in OwnerGroupProperty,
        on: ogp.taxkey == p.taxkey,
        group_by: ogp.name,
        order_by: [desc: sum(p.number_units)],
        select: %{
          name: ogp.name,
          total_properties: count(p.number_units),
          total_units: sum(p.number_units)
        }
      )

    query =
      if owner_query != "" do
        formatted_query = format_query(owner_query)

        from(p in query,
          where: fragment("owner_group LIKE ?", ^formatted_query)
        )
      else
        query
      end

    Repo.all(query)
  end

  def search_properties(owner_query, address_query) do
    query =
      from(pf in PropertyFts,
        join: p in Property,
        on: p.taxkey == pf.taxkey,
        select: p,
        order_by: [asc: :rank],
        limit: 1000
      )

    query =
      if owner_query != "" do
        formatted_query = format_query(owner_query)

        from(p in query,
          where: fragment("owner_group LIKE ?", ^formatted_query)
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
      where: ogp.name == ^name
    )
    |> Repo.all()
  end

  @doc """
  Gets a single property.

  Raises `Ecto.NoResultsError` if the Property does not exist.

  ## Examples

      iex> get_property!(123)
      %Property{}

      iex> get_property!(456)
      ** (Ecto.NoResultsError)

  """
  def get_property!(id) do
    Repo.get!(Property, id)
    |> Repo.preload(:owner_group)
  end

  def get_property_by_taxkey!(taxkey) do
    Repo.get_by!(Property, taxkey: taxkey)
    |> Repo.preload(:owner_group)
  end

  @doc """
  Creates a property.

  ## Examples

      iex> create_property(%{field: value})
      {:ok, %Property{}}

      iex> create_property(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_property(attrs \\ %{}) do
    %Property{}
    |> Property.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a property.

  ## Examples

      iex> update_property(property, %{field: new_value})
      {:ok, %Property{}}

      iex> update_property(property, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_property(%Property{} = property, attrs) do
    property
    |> Property.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a property.

  ## Examples

      iex> delete_property(property)
      {:ok, %Property{}}

      iex> delete_property(property)
      {:error, %Ecto.Changeset{}}

  """
  def delete_property(%Property{} = property) do
    Repo.delete(property)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking property changes.

  ## Examples

      iex> change_property(property)
      %Ecto.Changeset{data: %Property{}}

  """
  def change_property(%Property{} = property, attrs \\ %{}) do
    Property.changeset(property, attrs)
  end

  @doc """
  Returns the list of owner_groups_properties.

  ## Examples

      iex> list_owner_groups_properties()
      [%OwnerGroupProperty{}, ...]

  """
  def list_owner_groups_properties do
    Repo.all(OwnerGroupProperty)
  end

  @doc """
  Gets a single owner_group_property.

  Raises `Ecto.NoResultsError` if the Owner group property does not exist.

  ## Examples

      iex> get_owner_group_property!(123)
      %OwnerGroupProperty{}

      iex> get_owner_group_property!(456)
      ** (Ecto.NoResultsError)

  """
  def get_owner_group_property!(id), do: Repo.get!(OwnerGroupProperty, id)

  def get_owner_group_property_by_name(name) do
    from(ogp in OwnerGroupProperty,
      where: ogp.name == ^name,
      limit: 1
    )
    |> Repo.one!()
  end

  @doc """
  Creates a owner_group_property.

  ## Examples

      iex> create_owner_group_property(%{field: value})
      {:ok, %OwnerGroupProperty{}}

      iex> create_owner_group_property(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_owner_group_property(attrs \\ %{}) do
    %OwnerGroupProperty{}
    |> OwnerGroupProperty.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a owner_group_property.

  ## Examples

      iex> update_owner_group_property(owner_group_property, %{field: new_value})
      {:ok, %OwnerGroupProperty{}}

      iex> update_owner_group_property(owner_group_property, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_owner_group_property(%OwnerGroupProperty{} = owner_group_property, attrs) do
    owner_group_property
    |> OwnerGroupProperty.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a owner_group_property.

  ## Examples

      iex> delete_owner_group_property(owner_group_property)
      {:ok, %OwnerGroupProperty{}}

      iex> delete_owner_group_property(owner_group_property)
      {:error, %Ecto.Changeset{}}

  """
  def delete_owner_group_property(%OwnerGroupProperty{} = owner_group_property) do
    Repo.delete(owner_group_property)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking owner_group_property changes.

  ## Examples

      iex> change_owner_group_property(owner_group_property)
      %Ecto.Changeset{data: %OwnerGroupProperty{}}

  """
  def change_owner_group_property(%OwnerGroupProperty{} = owner_group_property, attrs \\ %{}) do
    OwnerGroupProperty.changeset(owner_group_property, attrs)
  end
end
