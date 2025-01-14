defmodule SaleMonitor.PriceChecks.Failure do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "failures" do
    belongs_to :price_check, SaleMonitor.PriceChecks.PriceCheck, primary_key: true
    field :error, :string
  end

  @doc false
  def changeset(failure, attrs) do
    failure
    |> cast(attrs, [:error])
    |> validate_required([:error])
  end
end
