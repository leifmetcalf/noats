defmodule SaleMonitor.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :url, :string
    field :alertee, :string

    has_many :price_checks, SaleMonitor.PriceChecks.PriceCheck,
      preload_order: [desc: :inserted_at]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :url, :alertee])
    |> validate_required([:name, :url, :alertee])
  end
end
