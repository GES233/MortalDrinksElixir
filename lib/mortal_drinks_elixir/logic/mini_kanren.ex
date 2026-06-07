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
  defp conjoin_clause([]), do: quote(do: Core.unit(state))

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
    quote do: Core.disj(unquote(first), unquote(disjoin_all(rest)))
  end

  defmacro project(vars, do: body) do
    vars = List.wrap(vars)

    # 生成 walk_star 提取代码
    extracts =
      for v <- vars do
        quote do
          unquote(v) = Core.walk_star(unquote(v), s)
          _ = unquote(v)
        end
      end

    quote do
      fn %Core.State{subst: s} = state ->
        unquote_splicing(extracts)

        # 执行用户代码
        # 静态编译器觉得永远走不到属于函数的 clause，所以包一层
        case unquote(body) |> Function.identity() do
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

  defdelegate eq(u, v), to: Core
  defdelegate run(n, f), to: Core
  defdelegate run_all(f), to: Core

  @doc "`absento(sym, x)`: atom `sym` 不能出现在 `x` 的任意嵌套层级中。"
  @spec absento(term(), Core.Var.maybe_term()) :: Core.goal()
  def absento(sym, x) do
    fn %Core.State{subst: s, constraints: cs} = state ->
      x_w = Core.walk_star(x, s)

      cond do
        x_w == sym ->
          Core.mzero()

        Core.Var.var?(x_w) ->
          # single variable — store constraint
          Core.unit(%{state | constraints: [{:absento, sym, x} | cs]})

        ground?(x_w) ->
          # fully concrete — check immediately, no constraint needed
          if absento_ground?(sym, x_w) do
            Core.unit(state)
          else
            Core.mzero()
          end

        true ->
          # compound term with Vars inside — store for later re-check
          Core.unit(%{state | constraints: [{:absento, sym, x} | cs]})
      end
    end
  end

  defp ground?(%Core.Var{}), do: false
  defp ground?(term) when is_list(term), do: Enum.all?(term, &ground?/1)
  defp ground?(term) when is_tuple(term), do: term |> Tuple.to_list() |> Enum.all?(&ground?/1)
  defp ground?(_), do: true

  defp absento_ground?(sym, term) do
    cond do
      term == sym -> false
      is_list(term) -> Enum.all?(term, &absento_ground?(sym, &1))
      is_tuple(term) -> term |> Tuple.to_list() |> Enum.all?(&absento_ground?(sym, &1))
      true -> true
    end
  end

  @doc """
  Disequality constraint: `u =/= v`. 断言 u 和 v 永远不能统一。

  存储在 `state.extension.constraints` 中，每次 unify 成功后检查。
  """
  @spec diseq(Core.Var.maybe_term(), Core.Var.maybe_term()) :: Core.goal()
  def diseq(u, v) do
    fn %Core.State{subst: s, constraints: cs} = state ->
      if Core.walk_star(u, s) == Core.walk_star(v, s) do
        Core.mzero()
      else
        Core.unit(%{state | constraints: [{:diseq, u, v} | cs]})
      end
    end
  end
end
