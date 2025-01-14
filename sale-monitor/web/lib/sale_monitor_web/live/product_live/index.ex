defmodule SaleMonitorWeb.ProductLive.Index do
  use SaleMonitorWeb, :live_view

  alias SaleMonitor.PriceChecks
  alias SaleMonitor.Products
  alias SaleMonitor.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-[repeat(4,minmax(min-content,max-content))_auto] w-auto gap-2 m-2">
      <div class="grid col-span-4 grid-cols-subgrid">
        <div>Webpage</div>
        <div>Alertee</div>
        <div>Price</div>
        <div>Status</div>
      </div>
      <div :for={product_id <- @product_ids} class="grid col-span-5 grid-cols-subgrid">
        <div
          phx-click={JS.toggle(to: "#detail-#{product_id}")}
          class="grid col-span-4 grid-cols-subgrid cursor-pointer border border-black p-2"
        >
          <div>{@products[product_id].product.name}</div>
          <div>{@products[product_id].product.alertee}</div>
          <div>
            <%= if @products[product_id].last_success do %>
              <%= if @products[product_id].last_success.success.is_sale do %>
                <del>${@products[product_id].last_success.success.pre_sale_price}</del>
                ${@products[product_id].last_success.success.price}
              <% else %>
                ${@products[product_id].last_success.success.price}
              <% end %>
            <% else %>
              No price history
            <% end %>
          </div>
          <div>{@products[product_id].status}</div>
        </div>

        <div id={"detail-#{product_id}"} class="col-span-5">
          <.external_link href={@products[product_id].product.url}>
            {@products[product_id].product.name}
          </.external_link>
          <div>
            <.button phx-click="check" phx-value-id={product_id}>
              Check
            </.button>
            <.button phx-click="delete" phx-value-id={product_id}>
              Delete
            </.button>
          </div>
          <table class="border-separate border-spacing-2">
            <tbody>
              <tr :for={price_check <- @products[product_id].product.price_checks}>
                <td>{price_check.inserted_at}</td>

                <td>{if price_check.success, do: "success", else: "failure"}</td>
                <td>
                  {if price_check.success do
                    if price_check.success.is_sale do
                      "$#{price_check.success.price} reduced from $#{price_check.success.pre_sale_price}"
                    else
                      "$#{price_check.success.price}"
                    end
                  else
                    "Error: #{price_check.failure.error}"
                  end}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <.form for={@form} phx-change="validate" phx-submit="save" class="m-2">
      <input
        id={@form[:name].id}
        name={@form[:name].name}
        value={@form[:name].value}
        type="text"
        placeholder="Webpage name"
        class="border-black"
      />
      <input
        id={@form[:url].id}
        name={@form[:url].name}
        value={@form[:url].value}
        type="text"
        placeholder="Webpage URL"
        class="border-black"
      />
      <input
        id={@form[:alertee].id}
        name={@form[:alertee].name}
        value={@form[:alertee].value}
        type="text"
        placeholder="Alertee email"
        class="border-black"
      />
      <.button>Add Product</.button>
    </.form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    products_with_checks =
      Products.list_products_with_checks()

    product_ids = Enum.map(products_with_checks, & &1.id)

    product_map =
      Map.new(products_with_checks, fn p ->
        last_check = p.price_checks |> List.first()
        last_success = p.price_checks |> Enum.find(& &1.success)

        {p.id,
         %{
           product: p,
           status:
             cond do
               is_nil(last_check) -> "never checked"
               last_check.success -> "success"
               true -> "failure"
             end,
           last_success: last_success,
           last_check: last_check
         }}
      end)

    {:ok,
     socket
     |> assign(form: to_form(Products.change_product(%Product{})))
     |> assign(product_ids: product_ids)
     |> assign(products: product_map)}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset = Products.change_product(%Product{}, product_params)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    case Products.create_product(product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> assign(product_ids: socket.assigns.product_ids ++ [product.id])
         |> assign(
           products:
             Map.put(socket.assigns.products, product.id, %{
               product: product,
               status: "checking",
               last_success: nil,
               last_check: nil
             })
         )
         |> start_async(:check_product, fn -> PriceChecks.run_price_check(product) end,
           supervisor: SaleMonitor.TaskSupervisor
         )
         |> assign(form: to_form(Products.change_product(%Product{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _product} = Products.delete_product(product)

    {:noreply,
     socket
     |> assign(product_ids: socket.assigns.product_ids -- [id])
     |> assign(products: Map.delete(socket.assigns.products, id))}
  end

  @impl true
  def handle_event("check", %{"id" => id}, socket) do
    product = Products.get_product!(id)

    {:noreply,
     socket
     |> assign(
       products:
         Map.update!(
           socket.assigns.products,
           product.id,
           fn product -> %{product | status: "checking"} end
         )
     )
     |> start_async(:check_product, fn -> PriceChecks.run_price_check(product) end,
       supervisor: SaleMonitor.TaskSupervisor
     )}
  end

  @impl true
  def handle_async(:check_product, {:ok, {:ok, %{success: success} = price_check}}, socket)
      when not is_nil(success) do
    {:noreply,
     socket
     |> assign(
       products:
         Map.update!(
           socket.assigns.products,
           price_check.product_id,
           fn product ->
             %{
               product
               | last_success: price_check,
                 last_check: price_check,
                 status: "success",
                 product: %{
                   product.product
                   | price_checks: [price_check | product.product.price_checks]
                 }
             }
           end
         )
     )}
  end

  @impl true
  def handle_async(:check_product, {:ok, {:ok, %{failure: failure} = price_check}}, socket)
      when not is_nil(failure) do
    {:noreply,
     socket
     |> assign(
       products:
         Map.update!(
           socket.assigns.products,
           price_check.product_id,
           fn product ->
             %{
               product
               | last_check: price_check,
                 status: "failure",
                 product: %{
                   product.product
                   | price_checks: [price_check | product.product.price_checks]
                 }
             }
           end
         )
     )}
  end
end
