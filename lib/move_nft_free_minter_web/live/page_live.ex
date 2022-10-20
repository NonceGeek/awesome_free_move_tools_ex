defmodule MoveNFTFreeMinterWeb.PageLive do
  @moduledoc false

  use MoveNFTFreeMinterWeb, :live_view

  alias MoveNFTFreeMinter.AptosRPC

  @impl true
  def mount(_, session, socket) do
    {:ok,
     socket
     |> assign_new(:current_user, fn -> Map.get(session, "current_user") end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :index, _params) do
    orders = MoveNFTFreeMinter.Explorer.list_orders()

    socket
    |> assign(orders: orders)
    |> assign(page_header: "Order List")
  end

  @impl true
  def handle_event("buy-succeed", %{"hash" => hash}, socket) do
    {:ok, client} = AptosRPC.connect()

    with true <- AptosRPC.check_transaction_by_hash(client, hash) do
      msg =
        raw(
          "Marketplace buy token succeed: <a href='https://explorer.devnet.aptos.dev/txn/#{hash}?network=testnet' target='_blank' class='font-semibold underline hover:text-blue-800 dark:hover:text-blue-900'>#{hash}</a>. Give it a click if you like."
        )

      {:noreply,
       socket
       |> put_flash(:info, msg)
       |> push_redirect(to: Routes.profile_path(socket, :index))}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Marketplace buy token failed. ")}
    end
  end

  @impl true
  def handle_event("buy-token", %{"id" => order_id}, socket) do
    %{assigns: %{orders: orders}} = socket

    current_order = Enum.find(orders, fn order -> order.order_id == order_id end)

    if current_order do
      token = Map.take(current_order.token, ~w(creator collection_name name property_version)a)
      {:noreply, push_event(socket, "buy-token", %{token: token, order_id: current_order.order_id, price: current_order.price})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-2 space-x-4 max-w-[80rem] mx-auto">
      <div class="grid grid-cols-4 gap-6" id="offers" phx-hook="Aptos">
        <%= for item <- @orders do %>
          <div class="bg-white shadow-lg hover:shadow-xl rounded-lg ">
            <div class="bg-gray-400 h-64 rounded-t-lg p-4 bg-no-repeat bg-center bg-cover" style={"background-image: url(#{item.token.uri}"}>
            </div>
            <div class="flex justify-between items-start px-2 pt-2">
              <div class="p-2 flex-grow">
                <h1 class="font-medium text-xl font-poppins"><%= item.token.name %></h1>
                <p class="text-gray-500 font-nunito"><%= item.token.description %></p>
              </div>
              <div class="p-2 text-right">
                <div class="text-teal-500 font-semibold text-lg font-poppins"><%= item.price %> APT</div>
              </div>
            </div>
            <div class="flex justify-center items-center px-2 pb-2">
              <button class="block w-full bg-white hover:bg-gray-100 text-blue-700 border-2 border-blue-500 px-3 py-2 rounded uppercase font-medium" phx-click="buy-token" phx-value-id={item.order_id}>
              buy
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
