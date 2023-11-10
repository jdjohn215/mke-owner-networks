defmodule WhoOwnsWhat.Data.OwnerGroup do
  use Ecto.Schema
  alias WhoOwnsWhat.Data.Property

  schema "owner_groups" do
    field :name, :string
    field :total_assessed_value, :integer
    field :number_properties, :integer
    field :number_units, :integer

    timestamps()

    has_many :properties, {"owner_groups_properties", Property}
  end
end
