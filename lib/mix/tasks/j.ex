defmodule Mix.Tasks.J do
  @moduledoc """
  Extract ALL code into one project, to facilitate LMM's context fetching.
  """

  use Mix.Task

  def run(_args) do
    ex = File.cwd!()
    |> Path.join("lib/**/**.ex")
    |> Path.wildcard()
    |> Enum.reject(&String.contains?(&1, "mix"))
    |> Enum.map(&File.read!(&1))
    |> Enum.join("\n")
    |> String.trim()

    """
      #{File.read!("README.md")}

      # Source code

      ## JavaScript

      ```javascript
      // js/hooks/anime_renderer/scenes
      #{File.cwd!()
      |> Path.join("lib/web_interface/assets/js/hooks/anime_renderer/scenes/*.js")
      |> Path.wildcard()
      |> Enum.map(&File.read!/1)
      |> Enum.join("\n")
      }

      // js/hooks/anime_renderer/math_core.js
      #{File.read!("lib/web_interface/assets/js/hooks/anime_renderer/math_core.js")}

      // js/hooks/anime_renderer.js
      #{File.read!("lib/web_interface/assets/js/hooks/anime_renderer.js")}

      // js/app.js
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
