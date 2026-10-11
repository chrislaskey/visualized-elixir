defmodule SolarWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SolarWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 shadow-sm">
      <div class="flex-1">
        <div class="flex w-fit gap-6 justify-start">
          <a href="/" class="flex-1 flex items-center gap-1">
            <span class="font-semibold text-lg">Visualized</span><span class="font-light">Elixir</span>
          </a>
          <div class="opacity-30 hover:opacity-100">
            <.theme_toggle />
          </div>
        </div>
      </div>
      <div class="flex-none">
        <ul class="hidden sm:flex flex-column px-1 space-x-4 items-center">
          <li></li>
          <li>
            <.link
              navigate="/"
              class="px-3 py-1.5 text-sm font-semibold text-base-content hover:text-primary"
            >Home</.link>
          </li>
          <li>
            <.link
              navigate="/supervisors"
              class="px-3 py-1.5 text-sm font-semibold text-base-content hover:text-primary"
            >Supervisors</.link>
          </li>
          <li>
            <.link
              navigate="/dashboard"
              class="px-3 py-1.5 text-sm text-base-content hover:text-primary"
            >Live Dashboard</.link>
          </li>
          <li>
            <a
              href="https://github.com/chrislaskey/visualized-elixir"
              class="px-3 py-1.5 text-sm text-base-content hover:text-primary flex items-center gap-1"
            >
              GitHub
            </a>
          </li>
        </ul>
        <.mobile_nav />
      </div>
    </header>

    <main class="px-4 py-8 sm:px-6 lg:px-8">
      <div class="mx-auto space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  def mobile_nav(assigns) do
    ~H"""
    <nav class="sm:hidden">
      <details
        id="mobile-nav"
        class="dropdown dropdown-end"
        phx-click-away={JS.remove_attribute("open")}
      >
        <summary
          class="flex cursor-pointer list-none items-center rounded-lg p-2 text-base-content/70 select-none hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-bars-3" class="size-5" />
        </summary>

        <div class="dropdown-content z-30 mt-2 w-56 rounded-lg border border-base-300 bg-base-100 p-1.5 shadow-lg">
          <ul>
            <li>
              <.link
                navigate="/"
                class="block rounded-lg px-2.5 py-2 text-sm font-semibold text-base-content transition-colors hover:bg-base-200 hover:text-primary"
              >
                Home
              </.link>
            </li>
            <li>
              <.link
                navigate="/supervisors"
                class="block rounded-lg px-2.5 py-2 text-sm font-semibold text-base-content transition-colors hover:bg-base-200 hover:text-primary"
              >
                Supervisors
              </.link>
            </li>
            <li>
              <.link
                navigate="/dashboard"
                class="block rounded-lg px-2.5 py-2 text-sm text-base-content transition-colors hover:bg-base-200 hover:text-primary"
              >
                Live Dashboard
              </.link>
            </li>
            <li>
              <a
                href="https://github.com/chrislaskey/visualized-elixir"
                class="block rounded-lg px-2.5 py-2 text-sm text-base-content transition-colors hover:bg-base-200 hover:text-primary"
              >
                GitHub
              </a>
            </li>
          </ul>
        </div>
      </details>
    </nav>
    """
  end

  attr :navigate, :string, required: true
  slot :inner_block, required: true

  defp mobile_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="block rounded-lg px-2.5 py-2 text-sm font-medium text-base-content transition-colors hover:bg-base-200 hover:text-primary"
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
