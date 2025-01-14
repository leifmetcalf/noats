defmodule SaleMonitorWeb.Auth do
  def auth(conn, _opts) do
    auth_config = Application.get_env(:sale_monitor, :basic_auth)
    Plug.BasicAuth.basic_auth(conn, auth_config)
  end
end
