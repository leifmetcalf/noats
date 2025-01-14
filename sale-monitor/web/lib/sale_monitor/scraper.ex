defmodule SaleMonitor.Scraper do
  require Logger

  def scrape_price(url) do
    Logger.info("Scraping #{url}")

    request =
      Req.new(
        url: Application.get_env(:sale_monitor, SaleMonitor.Scraper)[:url],
        params: %{url: url},
        decode_json: [floats: :decimals, keys: :atoms],
        connect_options: [
          timeout: 60_000
        ]
      )

    case Req.get!(request).body do
      %{error: error} ->
        {:error, error}

      %{result: result} ->
        {:ok, result}
    end
  end
end
