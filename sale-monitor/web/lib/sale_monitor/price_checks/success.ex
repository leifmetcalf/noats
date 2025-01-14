defmodule SaleMonitor.PriceChecks.Success do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "successes" do
    belongs_to :price_check, SaleMonitor.PriceChecks.PriceCheck, primary_key: true

    field :price, :decimal
    field :is_sale, :boolean, default: false
    field :pre_sale_price, :decimal
  end

  @doc false
  def changeset(success, attrs) do
    success
    |> cast(attrs, [:price, :is_sale, :pre_sale_price])
    |> validate_required([:price, :is_sale])
  end
end
