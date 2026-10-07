defmodule SolarWeb.ExplorationsLive.Shared do
  @moduledoc """
  The pieces every exploration page under `/explorations` uses: the link back
  to the index, and the section / option scaffolding that lays variations out
  side by side on a dotted canvas-like background.
  """

  use SolarWeb, :html

  @doc "The link back to the exploration index, above a page's heading."
  def back_link(assigns) do
    ~H"""
    <p class="text-sm">
      <.link navigate="/explorations" class="text-primary hover:underline">
        ← Explorations
      </.link>
    </p>
    """
  end

  @doc """
  A titled group of options. The title gets an anchor so sections can be
  linked to from the page's table of contents.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true
  slot :intro

  def section(assigns) do
    ~H"""
    <section id={@id} class="scroll-mt-6 space-y-4">
      <header class="space-y-1 border-b border-base-300 pb-2">
        <h2 class="text-lg font-semibold">{@title}</h2>
        <p :if={@intro != []} class="max-w-3xl text-sm text-base-content/70">
          {render_slot(@intro)}
        </p>
      </header>
      <div class="grid grid-cols-1 gap-4 xl:grid-cols-2">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  @doc """
  One option: a label, a note on what it tries, and the drawing itself on a
  dotted background so it reads like a node on the canvas.
  """
  attr :code, :string, required: true
  attr :title, :string, required: true
  attr :note, :string, default: nil
  attr :wide, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def option(assigns) do
    ~H"""
    <article class={[
      "flex flex-col overflow-hidden rounded-xl border border-base-300",
      @wide && "xl:col-span-2"
    ]}>
      <header class="flex items-baseline gap-3 border-b border-base-300 bg-base-100 px-4 py-2.5">
        <span class="font-mono text-xs text-primary">{@code}</span>
        <h3 class="text-sm font-semibold">{@title}</h3>
      </header>
      <div class={[
        "flex flex-1 flex-wrap items-start gap-8 p-6",
        "bg-base-200/40 bg-[radial-gradient(circle,var(--color-base-300)_1px,transparent_1px)] bg-[size:18px_18px]",
        @class
      ]}>
        {render_slot(@inner_block)}
      </div>
      <p
        :if={@note}
        class="border-t border-base-300 bg-base-100 px-4 py-2.5 text-xs leading-relaxed text-base-content/70"
      >
        {@note}
      </p>
    </article>
    """
  end

  @doc "A small caption under a drawing, for naming the state it shows."
  slot :inner_block, required: true

  def caption(assigns) do
    ~H"""
    <p class="mt-2 text-center text-[11px] text-base-content/50">{render_slot(@inner_block)}</p>
    """
  end
end
