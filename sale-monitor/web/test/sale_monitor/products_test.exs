defmodule SaleMonitor.ProductsTest do
  use SaleMonitor.DataCase

  alias SaleMonitor.Products

  describe "products" do
    alias SaleMonitor.Products.Product

    import SaleMonitor.ProductsFixtures

    @invalid_attrs %{url: nil, alertee: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{url: "some url", alertee: "some alertee"}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.url == "some url"
      assert product.alertee == "some alertee"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{url: "some updated url", alertee: "some updated alertee"}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.url == "some updated url"
      assert product.alertee == "some updated alertee"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end
end
