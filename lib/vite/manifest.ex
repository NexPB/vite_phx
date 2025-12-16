defmodule Vite.Manifest do
  @moduledoc """
  Reads the Vite manifest file and converts it to a list of entries
  """
  alias Vite.{Config, ManifestReader}

  @type entry_value :: binary() | list(binary()) | nil

  @spec read(binary()) :: map()
  def read(manifest_path) do
    manifest_path =
      if Config.current_env() == :prod do
        Config.in_release_path(manifest_path)
      else
        manifest_path
      end

    ManifestReader.read_vite(manifest_path)
  end

  @spec entries(binary()) :: [list()]
  def entries(manifest_path) do
    manifest_path
    |> read()
    |> Enum.filter(&isEntry/1)
    |> Enum.map(fn {_, value} -> value end)
    |> Enum.map(fn entry -> convert_item(manifest_path, entry, []) end)
  end

  @spec entry(binary()) :: list()
  @spec entry(binary(), Keyword.t()) :: list()
  def entry(entry_name, opts \\ []) do
    manifest_path = Keyword.get_lazy(opts, :manifest_path, fn -> Config.vite_manifest() end)

    manifest_path
    |> entries()
    |> Enum.find(&(Keyword.get(&1, :entry_name) == entry_name))
  end

  @spec isEntry({any, map()}) :: boolean()
  defp isEntry({_key, value}) do
    Map.get(value, "isEntry") == true
  end

  # %{
  #   "css" => ["assets/main.c14674d5.css"],
  #   "file" => "assets/main.9160cfe1.js",
  #   "imports" => ["_vendor.3b127d10.js"],
  #   "isEntry" => true,
  #   "src" => "src/main.tsx"
  # }
  defp convert_item(manifest_path, raw_data, acc) do
    css = Map.get(raw_data, "css", [])
    entry_name = Map.get(raw_data, "src")
    imports = Map.get(raw_data, "imports", [])
    acc = acc ++ [{:entry_name, entry_name}]
    acc = acc ++ Enum.map(css, fn file -> {:css, file} end)
    acc = acc ++ [{:module, Map.get(raw_data, "file")}]

    acc =
      Enum.reduce(imports, acc, fn file, innerAcc ->
        handle_import(manifest_path, file, innerAcc)
      end)

    acc |> Enum.uniq()
  end

  defp convert_item(manifest_path, raw_data, acc, :import) do
    css = Map.get(raw_data, "css", [])
    imports = Map.get(raw_data, "imports", [])
    import_module = {:import_module, Map.get(raw_data, "file")}

    acc = acc ++ Enum.map(css, fn file -> {:import_css, file} end)

    case Enum.member?(acc, import_module) do
      true ->
        acc

      false ->
        acc = acc ++ [import_module]

        acc =
          Enum.reduce(imports, acc, fn file, innerAcc ->
            handle_import(manifest_path, file, innerAcc)
          end)

        Enum.uniq(acc)
    end
  end

  @spec handle_import(binary(), binary(), list()) :: list()
  def handle_import(manifest_path, file, acc) do
    raw_data =
      manifest_path
      |> read()
      |> Map.get(file)

    convert_item(manifest_path, raw_data, acc, :import)
  end
end
