defmodule Vite do
  @moduledoc """
  Documentation for `Vite`.
  """
  use Phoenix.Component

  alias Vite.Config

  attr :src, :string, required: true
  attr :entries, :list
  attr :port, :integer
  attr :is_react, :boolean

  def head(assigns) do
    assigns =
      assigns
      |> assign_new(:is_react, fn -> Config.react?() end)
      |> assign_new(:entries, fn ->
        if production?() do
          Vite.Manifest.entry(assigns[:src])
        else
          []
        end
      end)

    if not production?() do
      assigns =
        assign(assigns, :dev_server, Config.dev_server_address(port: assigns[:port]))

      ~H"""
      <.react_refresh dev_server={@dev_server} is_react={@is_react} />
      <script type="module" src={@dev_server <> "/@vite/client"}></script>
      <script type="module" src={@dev_server <> "/" <> @src}></script>
      """
    else
      IO.inspect(assigns, label: "Vite Head Assigns for prod")

      ~H"""
      <.entry
        :for={{type, src} <- assigns[:entries]}
        type={type}
        entry={src}
      />
      """
    end
  end

  attr :type, :atom, required: true
  attr :entry, :string, required: true

  def entry(assigns) do
    IO.inspect(assigns, label: "Vite Entry Assigns")

    case assigns[:type] do
      :entry_name ->
        # Ignore as it is the start
        ~H""

      :css ->
        ~H"""
        <link phx-track-static rel="stylesheet" href={"/" <> @entry}>
        """

      :import_css ->
        ~H"""
        <link phx-track-static rel="stylesheet" href={"/" <> @entry}>
        """

      :import_module ->
        ~H"""
        <link rel="modulepreload" href={"/" <> @entry}>
        """

      :module ->
        ~H"""
        <script type="module" crossorigin defer phx-track-static src={"/" <> @entry}></script>
        """
    end
  end

  attr :dev_server, :string
  attr :port, :integer
  attr :is_react, :boolean

  def react_refresh(assigns) do
    assigns =
      assigns
      |> assign_new(:dev_server, fn -> Config.dev_server_address(port: assigns[:port]) end)
      |> assign_new(:is_react, fn -> Config.react?() end)

    ~H"""
    <script :if={@is_react} type="module">
      import RefreshRuntime from '<%= assigns[:dev_server] %>/@react-refresh'
      RefreshRuntime.injectIntoGlobalHook(window)
      window.$RefreshReg$ = () => {}
      window.$RefreshSig$ = () => (type) => type
      window.__vite_plugin_react_preamble_installed__ = true
    </script>
    """
  end

  def production?() do
    Vite.Config.current_env() == :prod
  end
end
