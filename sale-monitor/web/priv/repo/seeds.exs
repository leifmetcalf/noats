# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SaleMonitor.Repo.insert!(%SaleMonitor.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SaleMonitor.Products

{:ok, _} =
  Products.create_product(%{
    name: "Coles cat food",
    url:
      "https://www.coles.com.au/product/fussy-cat-grain-free-adult-dry-cat-food-salmon-and-oceanfish-with-olive-oil-2.5kg-2739960",
    alertee: "me@leif.nz"
  })

{:ok, _} =
  Products.create_product(%{
    name: "Woolworths cat food",
    url:
      "https://www.woolworths.com.au/shop/productdetails/478375/fussy-cat-grain-free-adult-dry-cat-food-salmon-whitefish-olive-oil",
    alertee: "me@leif.nz"
  })

{:ok, _} =
  Products.create_product(%{
    name: "Chemist Warehouse shampoo",
    url: "https://www.chemistwarehouse.com.au/buy/105472/joico-joifull-volume-shampoo-300ml",
    alertee: "me@leif.nz"
  })
