defmodule MoveNFTFreeMinterWeb.AboutLive do
    @moduledoc false

    use MoveNFTFreeMinterWeb, :live_view

    @impl true
    def mount(_, _session, socket) do
      {:ok,
       socket}
    end

    @impl true
    def handle_params(_params, _url, socket) do
      {:noreply, socket}
    end

    @impl true
    def render(assigns) do
      ~H"""
        <center>
          <p class="text-5xl"><b>About Us</b></p>
          <br>
          <br>
          <p>Telegram: @leeduckgo</p>
          <p>Wechat: 197626581</p>
        </center>
      """
    end
  end
