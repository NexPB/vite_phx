defmodule Vite.Config do
  require Logger

  def all() do
    %{
      release_app: release_app(),
      current_env: current_env(),
      vite_manifest: vite_manifest(),
      json_library: json_library(),
      dev_server_address: dev_server_address()
    }
  end

  def release_app() do
    Application.get_env(:vite_phx, :release_app) ||
      Logger.error(
        "Configuration for Vite release_app missing! Provide via: `config :vite_phx, :release_app, :my_app`"
      )
  end

  def in_release_path(file) do
    Application.app_dir(release_app(), file)
  end

  def current_env() do
    Application.get_env(:vite_phx, :environment, :dev)
  end

  def vite_manifest() do
    Application.get_env(:vite_phx, :vite_manifest) || "priv/static/.vite/manifest.json"
  end

  def dev_server_address(opts \\ []) do
    port = Keyword.get(opts, :port)
    url = Application.get_env(:vite_phx, :dev_server_address) || "http://localhost:5173"
    uri = URI.parse(url)

    uri =
      if is_integer(port) do
        %{uri | port: port}
      else
        uri
      end

    URI.to_string(uri)
  end

  def json_library() do
    Application.get_env(:vite_phx, :json_library, Phoenix.json_library())
  end

  def react?() do
    Application.get_env(:vite_phx, :react, false)
  end
end
