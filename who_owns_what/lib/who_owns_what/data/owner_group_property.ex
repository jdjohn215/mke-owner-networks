defmodule WhoOwnsWhat.Data.OwnerGroupProperty do
  use Ecto.Schema
  import Ecto.Changeset
  alias WhoOwnsWhat.Data.OwnerGroup
  alias WhoOwnsWhat.Data.Property

  schema "owner_groups_properties" do
    field :owner_group_name, :string
    field :taxkey, :string
    field :wdfi_group_id, :string
    field :group_source, :string

    belongs_to :owner_group, OwnerGroup,
      foreign_key: :owner_group_name,
      references: :name,
      define_field: false

    belongs_to :property, Property,
      foreign_key: :taxkey,
      references: :taxkey,
      define_field: false

    timestamps()
  end

  @doc false
  def changeset(owner_group_property, attrs) do
    owner_group_property
    |> cast(attrs, [:taxkey, :owner_group_name])
    |> validate_required([:taxkey, :owner_group_name])
  end
end
