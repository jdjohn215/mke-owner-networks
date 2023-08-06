defmodule WhoOwnsWhat.Data.OwnerGroupProperty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "owner_groups_properties" do
    field :name, :string
    field :taxkey, :string

    timestamps()
  end

  @doc false
  def changeset(owner_group_property, attrs) do
    owner_group_property
    |> cast(attrs, [:taxkey, :name])
    |> validate_required([:taxkey, :name])
  end
end
