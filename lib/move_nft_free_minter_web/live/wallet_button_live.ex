defmodule MoveNFTFreeMinterWeb.WalletButtonLive do
  @moduledoc false

  use MoveNFTFreeMinterWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign_new(:user_token, fn -> session["user_token"] end)
     |> assign_new(:user, fn -> nil end)
     |> assign_new(:text, fn -> session["text"] end)
     |> assign_new(:id, fn -> session["id"] end)
     |> assign_new(:connected, fn -> false end)
     |> assign_new(:current_wallet_address, fn -> nil end)
     |> assign_new(:signed, fn -> false end)
     |> assign_new(:verify_signature, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <span title="wallet" id="wallet-button" phx-hook="Aptos">
      <%= cond do %>
        <% @connected and @id == "wallet-connect" -> %>
          <button
            id={@id}
            class="w-full inline-flex justify-center py-2 px-4 !border-gray-300 !text-gray-500 hover:bg-gray-50"
            phx-click="connect-metamask"
          >

            <a href="#" class="flex items-center p-3 text-base font-bold text-gray-900 bg-gray-50 rounded-lg hover:bg-gray-100 group hover:shadow dark:bg-gray-600 dark:hover:bg-gray-500 dark:text-white">
              <span class="flex-1 ml-3 whitespace-nowrap">Petra</span>
              <span class="inline-flex items-center justify-center px-2 py-0.5 ml-3 text-xs font-medium text-gray-500 bg-gray-200 rounded dark:bg-gray-700 dark:text-gray-400">Popular</span>
            </a>
          </button>

        <% not @connected and @id == "wallet-connect" -> %>
          <button
            id={@id}
            class="w-full inline-flex justify-center py-2 px-4 !border-gray-300 !text-gray-500 hover:bg-gray-50"
            phx-click="connect-petra"
          >

            <a href="#" class="flex items-center p-3 text-base font-bold text-gray-900 bg-gray-50 rounded-lg hover:bg-gray-100 group hover:shadow dark:bg-gray-600 dark:hover:bg-gray-500 dark:text-white">
              <span class="flex-1 ml-3 whitespace-nowrap">Petra</span>
              <span class="inline-flex items-center justify-center px-2 py-0.5 ml-3 text-xs font-medium text-gray-500 bg-gray-200 rounded dark:bg-gray-700 dark:text-gray-400">Popular</span>
            </a>
          </button>

        <% true -> %>
      <% end %>
    </span>
    """
  end

  @impl true
  def handle_event("account-check", params, socket) do
    {:noreply,
     socket
     |> assign(:connected, params["connected"])
     |> assign(:current_wallet_address, params["current_wallet_address"])}
  end

  @impl true
  def handle_event("get-current-wallet", _params, socket) do
    {:noreply, push_event(socket, "get-current-wallet", %{})}
  end

  @impl true
  def handle_event("connect-petra", _params, socket) do
    {:noreply, push_event(socket, "connect-petra", %{id: socket.assigns.id})}
  end
end
