# `vite_phx`

[Vite.js]: https://vitejs.dev/

Helps you to integrate [Vite.js] with Phoenix.
NOTE: This is a fork of the original but modified to use newer Phoenix syntax.

## Instructions

Add following line to your layout template in the `<head />` tag:

```elixir
<head>
  <Vite.head src="src/main.tsx" />
<head>
```

## Configuration

```elixir
# in config/config.exs

# Configure Vite
config :vite_phx,
  release_app: :your_phx_app,
  # to tell prod and dev env appart
  environment: config_env(),
  # if you're using react
  react: true,
  # this manifest is different from the Phoenix "cache_manifest.json"!
  vite_manifest: "priv/static/.vite/manifest.json", # optional
  phx_manifest: "priv/static/cache_manifest.json", # optional
  dev_server_address: "http://localhost:5173" # optional
```

## Installation

The package can be installed by adding `vite_phx` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:vite_phx, git: "https://github.com/NexPB/vite_phx.git", tag: ""}
  ]
end
```
