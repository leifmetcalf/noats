defmodule SaleMonitor.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias SaleMonitor.Repo

  alias SaleMonitor.Products.Product

  require Logger

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Gets a single product.

  ## Examples

      iex> get_product(123)
      %Product{}

      iex> get_product(456)
      nil

  """
  def get_product(id), do: Repo.get(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  @doc """
  Lists all products with their checks

  ## Examples

      iex> list_products_with_checks()
      [%Product{price_checks: [%PriceCheck{success: %Success{}, failure: %Failure{}}]}, ...]

  """
  def list_products_with_checks do
    Repo.all(
      from(product in Product,
        left_join: price_check in assoc(product, :price_checks),
        left_join: success in assoc(price_check, :success),
        left_join: failure in assoc(price_check, :failure),
        order_by: [asc: :inserted_at, desc: price_check.inserted_at],
        preload: [price_checks: {price_check, [success: success, failure: failure]}]
      )
    )
  end
end
