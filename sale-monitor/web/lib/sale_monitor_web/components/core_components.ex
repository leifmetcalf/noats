defmodule SaleMonitorWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders a button.
  """

  attr :rest, :global
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button class="bg-gray-200 p-1 rounded-md" {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a link to an external site.
  """

  attr :href, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def external_link(assigns) do
    ~H"""
    <.link target="_blank" href={@href} class={["underline text-sky-800", @class]} {@rest}>
      {render_slot(@inner_block)}
      <.icon name="hero-arrow-top-right-on-square-solid" class="size-4" />
    </.link>
    """
  end
end
