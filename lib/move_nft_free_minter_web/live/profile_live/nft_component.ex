defmodule MoveNFTFreeMinterWeb.ProfileLive.NFTComponent do
  @moduledoc false

  use MoveNFTFreeMinterWeb, :live_component

  alias MoveNFTFreeMinterWeb.Router.Helpers, as: Routes

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div class="text-sm font-medium text-center text-gray-500 border-b border-gray-200 dark:text-gray-400 dark:border-gray-700">
        <ul class="flex flex-wrap">
          <li class="mr-2">
            <%= link "NFTs", to: Routes.profile_path(@socket, :index, tab: "nft"), class: "inline-block p-4 text-blue-600 rounded-t-lg border-b-2 border-blue-600 active dark:text-blue-500 dark:border-blue-500 font-bold" %>
          </li>
          <li class="mr-2">
            <%= link "Offers", to: Routes.profile_path(@socket, :index, tab: "offer"), class: "inline-block p-4 rounded-t-lg border-b-2 border-transparent hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300 font-bold" %>
          </li>
        </ul>
      </div>

      <div class="my-4 space-x-4 mx-auto">
        <div class="grid grid-cols-4 gap-6">
          <%= for item <- @entries do %>
            <div class="bg-white shadow-lg hover:shadow-xl rounded-lg ">
              <div class="bg-gray-400 h-64 rounded-t-lg p-4 bg-no-repeat bg-center bg-cover" style={"background-image: url(#{item.token.uri}"}>
              </div>
              <div class="flex justify-between items-start px-2 pt-2">
                <div class="p-2 flex-grow">
                  <h1 class="font-medium text-xl font-poppins"><%= item.token.name %></h1>
                  <p class="text-gray-500 font-nunito"><%= item.token.description %></p>
                </div>
              </div>
              <div class="flex justify-center items-center px-2 pb-2">
                <%= link "List", to: Routes.profile_path(@socket, :list_token, item.id), class: "text-center block w-full bg-white hover:bg-gray-100 text-blue-700 border-2 border-blue-500 px-3 py-2 rounded uppercase font-medium" %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
