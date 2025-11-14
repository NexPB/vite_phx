defmodule Vite do
  @moduledoc """
  Documentation for `Vite`.
  """
  use Phoenix.Component

  alias Vite.Config

  attr :src, :string, required: true
  attr :entries, :list

  def head(assigns) do
    assigns = assign_new(assigns, :entries, fn ->
      if production?() do
        Vite.Manifest.entries(assigns[:src])
      else
        []
      end
    end)

    if not production?() do
      ~H"""
      <.react_refresh />
      <script type="module" src={Config.dev_server_address() <> "/@vite/client"}></script>
      <script type="module" src={Config.dev_server_address() <> "/" <> assigns[:src]}></script>
      """
    else
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

  def react_refresh(assigns) do
    assigns = assign_new(assigns, :dev_server, fn -> Config.dev_server_address() end)

    ~H"""
    <script :if={Config.react?()} type="module">
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
