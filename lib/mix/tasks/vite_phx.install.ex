defmodule Mix.Tasks.VitePhx.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Setup vite for your Phoenix project"
  end

  @spec example() :: String.t()
  def example do
    "mix vite_phx.install --react"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```sh
    #{example()}
    ```

    ## Options

    * `--react` - Setup Vite for React
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.VitePhx.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :vite_phx,
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [
          react: :boolean,
          input: :string
        ],
        # Default values for the options in the `schema`
        defaults: [
          react: false,
          input: "js/app.jsx"
        ],
        aliases: [
          i: :input
        ]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Ingniter.Project.app_name(igniter)

      igniter
      |> Igniter.Scribe.section("Modifying config", "", fn igniter ->
        vite_config_exs(igniter)
      end)
      |> Igniter.Scribe.section("Generating vite.config.js", "", fn igniter ->
        template = vite_config_file_template(igniter)

        igniter
        |> Igniter.create_new_file("/assets/vite.config.js", template)
      end)
      |> Igniter.add_notice("""
      Please ensure to install the required npm packages:

      - vite
      - @vitejs/plugin-react (if using React)

      And add the following scripts to your package.json:

      ```json
      "scripts": {
        "dev": "vite",
        "build": "vite build",
        "preview": "vite preview"
      }
      ```

      At last modify your layout generally `app.html.heex` to include:

      ```html
      <head>
        ...
        <Vite.head src="js/app.jsx" />
      </head>
      ```
      """)
    end

    defp vite_config_exs(igniter) do
      app_name = Igniter.Project.app_name(igniter)
      react? = igniter.args.options[:react]

      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :vite_phx,
        [:environment],
        {:code, Sourceror.parse_string!("config_env()")}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :vite_phx,
        [:release_app],
        {:code, Sourceror.parse_string!(app_name)}
      )
      |> then(fn igniter ->
        if react? do
          Igniter.Project.Config.configure(
            igniter,
            "config.exs",
            :vite_phx,
            [:react],
            {:code, Sourceror.parse_string!("true")}
          )
        else
          igniter
        end
      end)

      # template = """
      # config :vite_phx,
      #   release_app: :#{Atom.to_string(app)},
      #   environment: config_env()
      # """

      # if Keyword.get(opts, :react, false) do
      #   """
      #   #{template},
      #   react: true
      #   """
      # else
      #   template
      # end
    end

    defp phoenix_config_exs(igniter) do
      app_name = Igniter.Project.app_name(igniter)
      {igniter, endpoint} = Igniter.Libs.Phoenix.select_endpoint(igniter)

      if is_nil(endpoint) do
        raise "Could not find Phoenix endpoint for application #{inspect(app_name)}"
      end

      igniter
      |> Igniter.Project.Config.configure(
        "dev.exs",
        app_name,
        [endpoint, :watchers],
        {:code,
         Sourceror.parse_string!("""
         [
           pnpm: {
             "run",
             "dev",
             cd: Path.expand("../assets", __DIR__)
           }
         ]
         """)}
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :phoenix,
        [:static_url],
        {:code, Sourceror.parse_string!("[:host, System.get_env(\"APP_HOST\") || \"localhost\"]")}
      )
    end

    defp vite_config_file_template(igniter) do
      input_file = igniter.args.options[:input]
      react? = igniter.args.options[:react]

      """
      import { resolve } from 'path';
      import { defineConfig } from 'vite';
      #{if react?, do: "import react from '@vitejs/plugin-react';\n", else: ""}
      /**
      * https://github.com/LostKobrakai/phoenix_vite/blob/main/assets/js/index.ts
      * @param {import('vite').PluginOption} opts
      * @returns {import('vite').Plugin}
      */
      function phoenixVitePlugin(opts = {}) {
        return {
          name: "phoenix-vite",
          handleHotUpdate({ file, modules }) {
            if (!opts.pattern || !file.match(opts.pattern)) return;
            // replace current file module with importers, keep the rest
            return [...modules].flatMap((mod) => {
              if (mod.file == file) return [...mod.importers];
              return [mod];
            });
          },
          configureServer(_server) {
            process.stdin.on('close', () => {
              process.exit(0);
            });

            process.stdin.resume();
          },
        };
      }

      export default defineConfig(() => {
        return {
          plugins: [
            phoenixVitePlugin({ pattern: /\\.(ex|heex)$/ }),
            #{if react?, do: "react(),", else: ""}
          ],
          server: {
            strictPort: true,
            cors: {
              origin: process.env.APP_HOST,
            },
          },
          build: {
            target: 'es2020',
            outDir: '../priv/static',
            emptyOutDir: false,
            sourcemap: true,
            manifest: true,
            rollupOptions: {
              input: '#{input_file}',
            },
          },
          resolve: {
            alias: {
              '@': resolve(__dirname, 'js'),
            },
          },
        };
      });

      """
    end
  end
else
  defmodule Mix.Tasks.VitePhx.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'vite_phx.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
