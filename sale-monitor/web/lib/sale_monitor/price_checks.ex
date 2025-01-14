defmodule SaleMonitor.PriceChecks do
  import Ecto.Query

  alias SaleMonitor.SaleNotifier
  alias SaleMonitor.Repo
  alias SaleMonitor.Scraper
  alias SaleMonitor.PriceChecks.PriceCheck
  alias SaleMonitor.PriceChecks.Success
  alias SaleMonitor.Products
  alias SaleMonitor.Products.Product
  alias SaleMonitor.Mailer

  require Logger

  @doc """
  Creates a price check.

  ## Examples

      iex> create_price_check(product, %{success: %{price: 100, is_sale: true, pre_sale_price: 90}})
      {:ok, %PriceCheck{}}

      iex> create_price_check(product, %{failure: %{error: "Error scraping price"}})
      {:ok, %PriceCheck{}}

      iex> create_price_check(product, %{field: "bad_value"})
      {:error, %Ecto.Changeset{}}

  """
  def create_price_check(%Product{} = product, attrs \\ %{}) do
    with {:ok, price_check} =
           Ecto.build_assoc(product, :price_checks)
           |> PriceCheck.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(price_check, [:success, :failure])}
    end
  end

  defp notify(price_check, prev_price) do
    Logger.info(
      "Notifying about sale #{inspect(price_check.success)} with previous price #{inspect(prev_price)}"
    )

    SaleNotifier.notify(price_check, prev_price) |> Mailer.deliver()
  end

  @doc """
  Runs a price check for a product.

  ## Examples

      iex> run_price_check(product)
      {:ok, %PriceCheck{}}

      iex> run_price_check(bad_product)
      {:error, %Ecto.Changeset{}}

  """
  def run_price_check(%Product{} = product) do
    task =
      Task.Supervisor.async_nolink(SaleMonitor.TaskSupervisor, fn ->
        Scraper.scrape_price(product.url)
      end)

    attrs =
      case Task.yield(task, 600_000) || Task.shutdown(task) do
        {:ok, {:ok, result}} ->
          %{success: result}

        {:ok, {:error, error}} ->
          %{failure: %{error: error}}

        {:ok, _} ->
          %{failure: %{error: "AI returned invalid response"}}

        {:exit, _reason} ->
          %{failure: %{error: "Scrape client exited"}}

        nil ->
          %{failure: %{error: "Scrape timed out"}}
      end

    with {:ok, %PriceCheck{} = price_check} = create_price_check(product, attrs) do
      price_check = price_check |> Repo.preload([:product, :success, :failure])

      if not is_nil(price_check.success) do
        prev_price =
          Repo.one(
            from success in Success,
              left_join: price_check in assoc(success, :price_check),
              where: price_check.product_id == ^product.id and price_check.id != ^price_check.id,
              order_by: [desc: price_check.inserted_at],
              limit: 1,
              select: success.price
          )

        if is_nil(prev_price) or price_check.success.price < prev_price do
          notify(price_check, prev_price)
        end
      end

      {:ok, price_check}
    end
  end

  @doc """
  Checks all products for price changes.
  """
  def check_all_prices do
    Products.list_products()
    |> Enum.each(fn %{id: product_id} ->
      product = Products.get_product!(product_id)

      case run_price_check(product) do
        {:ok, price_check} ->
          Logger.info("Price check for product completed: #{inspect(price_check)}")
      end
    end)
  end
end
