defmodule MortalDrinksElixir.Logic.MiniKanren do
  alias MortalDrinksElixir.Logic.Core

  defmacro fresh(vars, do: block) do
    List.wrap(vars)
    |> Enum.reduce(block, fn var, acc ->
      quote do
        Core.call_fresh(fn unquote(var) -> unquote(acc) end)
      end
    end)
  end

  # defmacro conde(do: block) do

  defmacro project(vars, do: body) do
    vars = List.wrap(vars)

    # 生成 walk_star 提取代码
    extracts =
      for v <- vars do
        quote do: unquote(v) = Core.walk_star(unquote(v), s)
      end

    quote do
      fn %Core.State{subst: s} = state ->
        unquote_splicing(extracts)

        # 执行用户代码
        case unquote(body) do
          # 如果返回 nil 或 false，视为 goal 失败
          nil -> Core.mzero()
          false -> Core.mzero()
          # 如果返回一个 goal 函数，则执行它
          goal when is_function(goal, 1) -> goal.(state)
          # 如果返回 true 或其他，视为成功
          _ -> Core.unit(state)
        end
      end
    end
  end

  # 实现 =/= ？

  defdelegate eq(u, v), to: Core
  defdelegate run(n, f), to: Core
  defdelegate run_all(f), to: Core
end
