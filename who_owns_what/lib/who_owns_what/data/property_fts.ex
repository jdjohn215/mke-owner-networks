defmodule WhoOwnsWhat.Data.PropertyFts do
  use Ecto.Schema
  alias WhoOwnsWhat.Data

  @timestamps_opts false
  @primary_key {:id, :id, autogenerate: true, source: :rowid}
  schema "properties_fts" do
    field :taxkey, :string
    field :owner_name_1, :string
    field :owner_group, :string
    field :full_address, :string
    field :rank, :float, virtual: true

    belongs_to :property, Data.Property,
      foreign_key: :taxkey,
      references: :taxkey,
      define_field: false
  end
end
