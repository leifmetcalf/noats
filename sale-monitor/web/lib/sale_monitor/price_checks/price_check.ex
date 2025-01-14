defmodule SaleMonitor.PriceChecks.PriceCheck do
  use Ecto.Schema
  import Ecto.Changeset
  alias SaleMonitor.PriceChecks.Success
  alias SaleMonitor.PriceChecks.Failure

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "price_checks" do
    belongs_to :product, SaleMonitor.Products.Product
    # TODO: change to has_one_of [:success, :failure]
    has_one :success, SaleMonitor.PriceChecks.Success
    has_one :failure, SaleMonitor.PriceChecks.Failure

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(price_check, attrs) do
    price_check
    |> cast(attrs, [:product_id])
    |> cast_assoc(:success, with: &Success.changeset/2)
    |> cast_assoc(:failure, with: &Failure.changeset/2)
    # TODO: validate that exactly one of success or failure is present
    |> validate_required([:product_id])
  end
end
