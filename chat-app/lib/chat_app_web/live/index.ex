defmodule ChatAppWeb.IndexLive do
  use ChatAppWeb, :live_view

  alias ChatApp.Chat

  def render(assigns) do
    ~H"""
    <%= if !@avatar do %>
      <div class="h-dvh flex flex-col items-center justify-center">
        <h2 class="text-center mb-8 text-xl">Who are you?</h2>
        <.form
          for={@avatar_form}
          phx-submit="choose_avatar"
          class="flex flex-wrap justify-center gap-4 max-w-md"
        >
          <button :for={avatar <- @avatars} name={@avatar_form[:avatar].name} value={avatar}>
            <.avatar avatar={avatar} class="size-24" />
          </button>
        </.form>
      </div>
    <% else %>
      <div class="h-dvh flex flex-col justify-end ">
        <ul id="messages" phx-update="stream" class="flex flex-col-reverse overflow-y-scroll">
          <li :for={{dom_id, message} <- @streams.messages} id={dom_id} class="mb-2">
            <div class="flex">
              <.avatar avatar={message.name} class="size-12 p-1" />
              <div class="p-2 grow min-w-0 content-center">
                <p class="break-words"><%= message.message %></p>
              </div>
              <%= if message.name == @avatar do %>
                <.button
                  class="shrink-0"
                  phx-click="delete_message"
                  phx-value-id={message.id}
                  phx-disable-with="Deleting..."
                >
                  Delete
                </.button>
              <% end %>
            </div>
          </li>
        </ul>
        <.form for={@message_form} phx-change="validate" phx-submit="send" class="border-t">
          <div class="flex">
            <.avatar avatar={@avatar} class="size-12 p-1" />
            <input
              id={@message_form[:message].id}
              name={@message_form[:message].name}
              value={@message_form[:message].value}
              placeholder="Message"
              autofocus
              autocomplete="off"
              phx-hook="MessageInput"
              class="pl-2 grow focus:outline-none min-w-0"
            />
            <.button class="shrink-0" phx-disable-with="Sending...">Send</.button>
          </div>
        </.form>
      </div>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       :avatars,
       ["beans", "duck", "otter", "potted-plant", "biting-lip", "turtle", "new-moon-face"]
     )
     |> assign(avatar: nil)
     |> assign(avatar_form: to_form(%{}))}
  end

  def handle_event("choose_avatar", %{"avatar" => avatar}, socket) do
    ChatAppWeb.Endpoint.subscribe("chat")

    {:noreply,
     socket
     |> assign(avatar: avatar)
     |> assign(message_form: to_form(Chat.change_message(%Chat.Message{})))
     |> stream(:messages, Chat.list_messages())}
  end

  def handle_event("validate", %{"message" => messageParams}, socket) do
    changeset = Chat.change_message(%Chat.Message{}, messageParams)
    {:noreply, socket |> assign(message_form: to_form(changeset, action: :validate))}
  end

  def handle_event("send", %{"message" => message_params}, socket) do
    case Chat.create_message(message_params |> Map.put("name", socket.assigns.avatar)) do
      {:ok, message} ->
        ChatAppWeb.Endpoint.broadcast("chat", "new_message", %{message: message})

        {:noreply,
         socket
         |> assign(message_form: to_form(Chat.change_message(%Chat.Message{})))
         |> push_event("clear-input-set-focus", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(message_form: to_form(changeset))}
    end
  end

  def handle_event("delete_message", %{"id" => id}, socket) do
    message = Chat.get_message!(id)

    case Chat.delete_message(message) do
      {:ok, _message} ->
        ChatAppWeb.Endpoint.broadcast("chat", "delete_message", %{message: message})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_info(%{event: "new_message", payload: %{message: message}}, socket) do
    {:noreply, socket |> stream_insert(:messages, message, at: 0)}
  end

  def handle_info(%{event: "delete_message", payload: %{message: message}}, socket) do
    {:noreply, socket |> stream_delete(:messages, message)}
  end
end
