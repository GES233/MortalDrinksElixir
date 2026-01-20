defmodule Mix.Tasks.J do
  @moduledoc """
  Extract ALL code into one project, to facilitate LMM's context fetching.
  """

  use Mix.Task

  def run(_args) do
    ex = Path.wildcard("lib/**/**.ex")
    |> Enum.reject(&String.contains?(&1, "mix"))
    |> Enum.map(&"# #{&1}\n#{File.read!(&1)}")
    |> Enum.join("\n")
    |> String.trim()

    js = Path.wildcard("lib/web_interface/assets/js/hooks/anime_renderer/scenes/*.js")
      |> Enum.map(&"// #{&1}\n#{File.read!(&1)}")
      |> Enum.join("\n\n")

    """
      #{File.read!("README.md")}

      # Source code

      ## JavaScript

      ```javascript
      #{js}

      // lib/web_interface/assets/js/hooks/anime_renderer/math_core.js
      #{File.read!("lib/web_interface/assets/js/hooks/anime_renderer/math_core.js")}

      // lib/web_interface/assets/js/hooks/anime_renderer/index.js
      #{File.read!("lib/web_interface/assets/js/hooks/anime_renderer/index.js")}

      // lib/web_interface/assets/js/app.js
      #{File.read!("lib/web_interface/assets/js/app.js")}
      ```

      ## CSS

      Use TailwindCSSv4

      ```tailwindcss
      #{File.read!("lib/web_interface/assets/css/app.css")}
      ```

      ## Config

      ```elixir
      #{File.read!("config.exs")}
      ```

      ## Lib

      ```elixir
      #{File.read!("mix.exs")}

      #{ex}
      ```
      """
    |> then(&File.write!(Path.join(File.cwd!(), "_build/code.md"), &1))
  end
end
