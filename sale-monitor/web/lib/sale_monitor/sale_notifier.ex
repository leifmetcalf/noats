defmodule SaleMonitor.SaleNotifier do
  import Swoosh.Email
  alias SaleMonitor.PriceChecks.PriceCheck

  def notify(
        %PriceCheck{success: success} = price_check,
        prev_price
      ) do
    new()
    |> to(price_check.product.alertee)
    |> from("sale@noats.nz")
    |> subject("Sale alert: #{price_check.product.name}")
    |> text_body("""
    url: #{price_check.product.url}
    current price: #{success.price}
    previous price: #{prev_price}
    claimed non-sale price: #{success.pre_sale_price}
    """)
  end
end
