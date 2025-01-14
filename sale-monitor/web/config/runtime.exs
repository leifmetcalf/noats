import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/sale_monitor start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :sale_monitor, SaleMonitorWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :sale_monitor, SaleMonitor.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "sale.noats.nz"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :sale_monitor, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :sale_monitor, SaleMonitorWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  mailpace_token =
    System.get_env("MAILPACE_TOKEN") ||
      raise """
      environment variable MAILPACE_TOKEN is missing.
      """

  config :sale_monitor, SaleMonitor.Mailer,
    adapter: Swoosh.Adapters.MailPace,
    api_key: mailpace_token

  site_password =
    System.get_env("SITE_PASSWORD") ||
      raise """
      environment variable SITE_PASSWORD is missing.
      """

  config :sale_monitor, :basic_auth, username: "user", password: site_password

  scraper_url =
    System.get_env("SCRAPER_URL") ||
      raise """
      environment variable SCRAPER_URL is missing.
      """

  config :sale_monitor, SaleMonitor.Scraper, url: scraper_url
end

mailpace_token =
  System.get_env("MAILPACE_TOKEN") ||
    raise """
    environment variable MAILPACE_TOKEN is missing.
    """

config :sale_monitor, SaleMonitor.Mailer,
  adapter: Swoosh.Adapters.MailPace,
  api_key: mailpace_token
