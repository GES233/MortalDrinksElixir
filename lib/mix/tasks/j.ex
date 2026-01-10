defmodule Mix.Tasks.J do
  @moduledoc """
  Extract ALL code into one project, to facilitate LMM's context fetching.
  """

  use Mix.Task

  def run(_args) do
    File.cwd!()
    |> Path.join("lib/**/**.ex")
    |> Path.wildcard()
    |> Enum.reject(&String.contains?(&1, "mix"))
    |> Enum.map(&File.read!(&1))
    |> Enum.join("\n")
    |> String.trim()
    |> then(
      &"""
      #{File.read!("README.md")}

      # Source code

      ## JavaScript

      ```javascript
      #{File.read!("lib/web_interface/assets/js/app.js")}
      ```

      ## Config

      ```elixir
      #{File.read!("config.exs")}
      ```

      ## Lib

      ```elixir
      #{File.read!("mix.exs")}

      #{&1}
      ```
      """
    )
    |> then(&File.write!(Path.join(File.cwd!(), "_build/code.md"), &1))
  end
end
