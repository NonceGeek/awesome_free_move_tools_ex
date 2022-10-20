defmodule MoveNFTFreeMinterWeb.ProfileLive do
  @moduledoc false

  use MoveNFTFreeMinterWeb, :live_view

  alias MoveNFTFreeMinterWeb.Router.Helpers, as: Routes

  alias MoveNFTFreeMinter.{Explorer, AptosRPC}
  alias MoveNFTFreeMinterWeb.ProfileLive.{NFTComponent, OfferComponent}

  @impl true
  def mount(_, session, socket) do
    {:ok,
     socket
     |> assign_new(:current_user, fn -> Map.get(session, "current_user") end)
     |> assign_new(:list_token_record, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :index, %{"tab" => "offer"}) do
    %{assigns: %{current_user: %{address: address}}} = socket
    entries = Explorer.list_user_ongoing_orders(address)

    socket
    |> assign(entries: entries)
    |> assign(tab: "offer")
    |> assign(page_header: "Profile")
  end

  def apply_action(socket, :index, _params) do
    %{assigns: %{current_user: %{address: address}}} = socket
    entries = Explorer.list_account_tokens(address)

    socket
    |> assign(entries: entries)
    |> assign(tab: "nft")
    |> assign(page_header: "Profile")
  end

  def apply_action(socket, :list_token, %{"id" => event_id}) do
    with {:ok, event} <- Explorer.get_event(event_id) do
      socket
      |> assign(event: event)
      |> assign(page_header: "Profile")
    else
      _ -> socket
    end
  end

  @impl true
  def handle_event("list-succeed", %{"hash" => hash}, socket) do
    {:ok, client} = AptosRPC.connect()

    with true <- AptosRPC.check_transaction_by_hash(client, hash) do
      msg =
        raw(
          "Marketplace list token succeed: <a href='https://explorer.devnet.aptos.dev/txn/#{hash}?network=testnet' target='_blank' class='font-semibold underline hover:text-blue-800 dark:hover:text-blue-900'>#{hash}</a>. Give it a click if you like."
        )

      {:noreply,
       socket
       |> put_flash(:info, msg)
       |> push_redirect(to: Routes.profile_path(socket, :index))}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Marketplace list token failed.")}
    end
  end

  @impl true
  def handle_event("list-token", %{"token" => %{"price" => price}}, socket) do
    %{assigns: %{event: event}} = socket

    if event do
      token = Map.take(event.token, ~w(creator collection_name name property_version)a)
      {:noreply, push_event(socket, "list-token", %{token: token, price: price})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-2 space-x-4 max-w-[80rem] mx-auto">
      <%= if @live_action == :index do %>
        <%= if @tab != "offer" do %>
          <.live_component module={NFTComponent} id="component-offer" entries={@entries} />
        <% else %>
          <.live_component module={OfferComponent} id="component-nft" entries={@entries} cancel_event="cancel" />
        <% end %>
      <% end %>
    </div>

    <%= if @live_action == :list_token do %>
      <.modal id="list-token-modal" show={true} class="min-w-[25%]" navigate={Routes.profile_path(@socket, :index)}>
        <div class="bg-white shadow-lg hover:shadow-xl rounded-lg" id="list-token" phx-hook="Aptos">
        <div class="bg-gray-400 h-64 rounded-t-lg p-4 bg-no-repeat bg-center bg-cover" style={"background-image: url(#{@event.token.uri}"}>
        </div>
          <div class="flex justify-between items-start px-2 pt-2">
            <div class="p-2 flex-grow">
              <h1 class="font-medium text-xl font-poppins"><%= @event.token.name %></h1>
              <p class="text-gray-500 font-nunito"><%= @event.token.description %></p>
            </div>
          </div>
          <div class="px-2 pb-2">
            <.form let={f} for={:token} phx-submit="list-token" class="space-y-2">
              <div class="flex">
                <%= number_input f, :price, class: "rounded-none rounded-l-lg bg-gray-50 border text-gray-900 focus:ring-blue-500 focus:border-blue-500 block flex-1 min-w-0 w-full text-sm border-gray-300 p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500", placeholder: "Price", required: true %>
                <span class="inline-flex items-center px-5 text-sm text-gray-900 bg-gray-200 rounded-r-md border border-r-0 border-gray-300 dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                  Aptos
                </span>
              </div>
              <%= submit "List", class: "block w-full bg-white hover:bg-gray-100 text-blue-700 border-2 border-blue-500 px-3 py-2 rounded uppercase font-medium" %>
            </.form>
          </div>
        </div>
      </.modal>
    <% end %>
    """
  end

  # defp get_wallet_tokens(account), do: MoveNFTFreeMinter.Explorer.list_account_tokens(account)
end
