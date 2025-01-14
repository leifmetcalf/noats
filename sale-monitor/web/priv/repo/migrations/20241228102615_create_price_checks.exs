defmodule SaleMonitor.Repo.Migrations.CreatePriceChecks do
  use Ecto.Migration

  def change do
    create table(:price_checks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:price_checks, [:product_id])

    create table(:successes, primary_key: false) do
      add :price_check_id, references(:price_checks, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :price, :decimal, null: false
      add :is_sale, :boolean, null: false
      add :pre_sale_price, :decimal
    end

    create index(:successes, [:price_check_id])

    create table(:failures, primary_key: false) do
      add :price_check_id, references(:price_checks, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :error, :string, null: false
    end

    create index(:failures, [:price_check_id])
  end
end
