defmodule MoveNFTFreeMinterWeb.LiveHelpers do
  @moduledoc false

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc "show wallet modal"
  def show_wallet_modal(js \\ %JS{}), do: show_modal(js, "wallet-modal")

  @doc """
  Shows a modal rendered with `modal/1`.
  """
  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      transition: {"ease-out duration-200", "opacity-0", "opacity-100"}
    )
  end

  @doc """
  Hides a modal rendered with `modal/1`.
  """
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.dispatch("click", to: "##{id}-return")
  end

  @doc """
  Wraps the given content in a modal dialog.

  ## Example

      <.modal id="edit-modal" patch={...}>
        <.live_component module={MyComponent}  />
      </.modal>

  """
  def modal(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:patch, fn -> nil end)
      |> assign_new(:navigate, fn -> nil end)
      |> assign_new(:class, fn -> "" end)
      |> assign(:attrs, assigns_to_attributes(assigns, [:id, :show, :patch, :navigate, :class]))

    ~H"""
    <div id={@id} class={"fixed z-[10000] inset-0 #{if @show, do: "fade-in", else: "hidden"}"} phx-remove={JS.transition("fade-out")} {@attrs}>
      <!-- Modal container -->
      <div class="h-screen flex items-center justify-center p-4">
        <!-- Overlay -->
        <div class="absolute z-0 inset-0 bg-gray-500 opacity-75" phx-click={hide_modal(@id)} aria-hidden="true"></div>
        <!-- Modal box -->
        <div class={"relative max-h-full overflow-y-auto bg-white rounded-lg shadow-xl #{@class}"}
          role="dialog"
          aria-modal="true"
          tabindex="0"
          autofocus
          phx-window-keydown={hide_modal(@id)}
          phx-click-away={hide_modal(@id)}
          phx-key="escape">
          <%= if @patch do %>
            <%= live_patch "", to: @patch, class: "hidden", id: "#{@id}-return" %>
            <% end %>
          <%= if @navigate do %>
            <%= live_redirect "", to: @navigate, class: "hidden", id: "#{@id}-return" %>
          <% end %>
          <button class="absolute top-6 right-6 text-gray-400 flex space-x-1 items-center"
            aria_label="close modal"
            phx-click={hide_modal(@id)}>
          </button>
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end
