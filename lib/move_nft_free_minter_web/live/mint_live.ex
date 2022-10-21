defmodule MoveNFTFreeMinterWeb.MintLive do
  @moduledoc false

  use MoveNFTFreeMinterWeb, :live_view

  alias MoveNFTFreeMinter.AptosRPC
  alias MoveNFTFreeMinter.Explorer.Model.Token

  @impl true
  def mount(_, session, socket) do
    {:ok,
     socket
     |> assign_new(:current_user, fn -> Map.get(session, "current_user") end)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :index, _params) do
    changeset = Token.input_changeset(%Token{}, %{})

    socket
    |> assign(changeset: changeset)
  end

  @impl true
  def handle_event("transfer", _attrs, socket) do
    # NOTICE
    # change to_address && amount here.
    payload = %{
      to: "0x2df41622c0c1baabaa73b2c24360d205e23e803959ebbcb0e5b80462165893ed",
      amount: "100000000"
    }

    {:noreply, push_event(socket, "transfer", payload)}
  end

  @impl true
  def handle_event("mint-succeed", %{"hash" => hash}, socket) do
    {:ok, client} = AptosRPC.connect()

    with true <- AptosRPC.check_transaction_by_hash(client, hash) do
      msg =
        raw(
          "Mint token succeed: <a href='https://explorer.aptoslabs.com/txn/#{hash}?network=testnet' target='_blank' class='font-semibold underline hover:text-blue-800 dark:hover:text-blue-900'>#{hash}</a>. Give it a click if you like."
        )

      {:noreply,
       socket
       |> assign(disabled_button: false)
       |> put_flash(:info, msg)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Mint token failed.")}
    end
  end

  @impl true
  def handle_event("mint-failed", _attrs, socket) do
    # TODO [ ]: handle mint-failed
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"token" => token_attrs}, socket) do
    changeset = Token.input_changeset(%Token{}, token_attrs)

    {:noreply,
     socket
     |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"token" => nft_attrs}, socket) do

    {:ok, client} = AptosRPC.connect()

    %{assigns: %{current_user: %{address: address}}} = socket
    %{"collection_name" => collection, "img_url" => img_url} = nft_attrs

    is_collection_created =
      client
      |> AptosRPC.get_collection_data(address, collection)
      |> case do
        {:ok, _} -> true
        _ -> false
      end


    IO.puts "is_collection_created: #{is_collection_created}, address: #{address}, collection: #{collection}"

    new_nft_attrs =
      nft_attrs
      |> Map.put("is_collection_created", is_collection_created)
      |> Map.put("image", img_url)

    {:noreply,
     socket
     |> push_event("mint-token", new_nft_attrs)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-2 space-x-4 max-w-[80rem] mx-auto" id="mint-token" phx-hook="Aptos">
      <div class="p-4 w-full bg-white rounded-lg border shadow-md sm:p-8 dark:bg-gray-800 dark:border-gray-700">
        <div class="flex justify-between items-center mb-4">
          <h5 class="text-xl font-bold leading-none text-gray-900 dark:text-white">Mint NFT</h5>
        </div>
        <div class="flow-root">
        <.form let={f} for={@changeset} phx-change="validate" phx-submit="save">

          <div class="mb-6">
            <%= label f, :collection_name, class: "block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300" do %>
              Your Collection Name
            <% end %>
            <%= text_input f, :collection_name,
              required: true,
              class: "shadow-sm bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500 dark:shadow-sm-light",
              placeholder: "collection name"
            %>
          </div>

          <div class="mb-6">
            <%= label f, :name, class: "block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300" do %>
              Your Token Name
            <% end %>
            <%= text_input f, :name, required: true, class: "shadow-sm bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500 dark:shadow-sm-light", placeholder: "token name"%>
          </div>

          <div class="mb-6">
            <%= label f, :description, class: "block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300" do %>
              Your Token Description
            <% end %>
            <%= textarea f, :description, required: true, class: "block p-2.5 w-full text-sm text-gray-900 bg-gray-50 rounded-lg border border-gray-300 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500", rows: 4, placeholder: "token description" %>
          </div>

          <div class="mb-6">
            <%= label f, :image, class: "block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300" do %>
              Your Token Image url
            <% end %>
            <%= text_input f, :img_url, required: true, class: "shadow-sm bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500 dark:shadow-sm-light", placeholder: "img url"%>
          </div>
          <%= submit "Mint", phx_disable_with: "Minting", class: "text-white font-bold bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-8 py-2.5 text-center inline-flex items-center mr-2 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800" %>
        </.form>
        </div>
      </div>
    </div>

    """
  end
end
