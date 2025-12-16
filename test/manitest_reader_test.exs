defmodule Vite.ManifestReaderTest do
  use ExUnit.Case

  alias Vite.ManifestReader
  alias Vite.ManifestReader.ManifestNotFoundError

  describe "read_vite/1" do
    test "to raise on missing file" do
      assert_raise ManifestNotFoundError, fn ->
        ManifestReader.read_vite("/nonexistent/path/manifest.json")
      end
    end
  end
end
