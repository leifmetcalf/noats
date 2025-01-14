defmodule SaleMonitor.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SaleMonitor.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        alertee: "some alertee",
        url: "some url"
      })
      |> SaleMonitor.Products.create_product()

    product
  end
end
