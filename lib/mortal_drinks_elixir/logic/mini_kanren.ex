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

  @doc """
  Multi-branch fair disjunction.

  Each clause is a list of goals (conjoined). Clauses are disjoined with
  fair interleaving.

  ## Usage

      conde do
        [eq(x, :a), eq(y, 1)]
        [eq(x, :b), eq(y, 2)]
      end

  """
  defmacro conde(do: block) do
    clauses =
      case block do
        {:__block__, _, lines} -> lines
        single -> [single]
      end

    clauses
    |> Enum.map(&conjoin_clause/1)
    |> disjoin_all()
  end

  # 把一个 clause（目标列表）用 conj 串起来
  defp conjoin_clause(clause) when is_list(clause) do
    Enum.reduce(clause, fn goal, acc ->
      quote do: Core.conj(unquote(acc), unquote(goal))
    end)
  end

  # 单个目标，不是列表
  defp conjoin_clause(single_goal), do: single_goal

  # 把多个 conjoined goal 用 disj 串起来
  defp disjoin_all([single]), do: single

  defp disjoin_all([first | rest]) do
    Enum.reduce(rest, first, fn goal, acc ->
      quote do: Core.disj(unquote(goal), unquote(acc))
    end)
  end

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
