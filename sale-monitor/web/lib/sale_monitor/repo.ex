defmodule SaleMonitor.Repo do
  use Ecto.Repo,
    otp_app: :sale_monitor,
    adapter: Ecto.Adapters.Postgres
end
