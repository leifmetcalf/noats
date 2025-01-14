defmodule ChatApp.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :message, :text, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
