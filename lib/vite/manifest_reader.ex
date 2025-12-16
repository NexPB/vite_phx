defmodule Vite.ManifestReader do
  @moduledoc """
  Finds `manifest.json` in releases, keeps the content in-memory
  """
  alias Vite.{Cache, Config}

  defmodule ManifestNotFoundError do
    defexception [:manifest_file]

    @impl true
    def message(e) do
      """
      Could not find static manifest at #{inspect(e.manifest_file)}.
        Run "mix phx.digest" after building your static files
        or remove the configuration from "config/prod.exs".
      """
    end
  end

  def read_vite(manifest_path) do
    cache_key = cache_key(manifest_path)

    case Cache.get(cache_key) do
      nil ->
        res = read_vite_file(manifest_path)
        Cache.put(cache_key, res)
        res

      res ->
        res
    end
  end

  defp read_vite_file(manifest_path) do
    if File.exists?(manifest_path) do
      manifest_path
      |> File.read!()
      |> Config.json_library().decode!()
    else
      raise ManifestNotFoundError, manifest_file: manifest_path
    end
  end

  defp cache_key(manifest_path) do
    {:vite_manifest, manifest_path}
  end
end
