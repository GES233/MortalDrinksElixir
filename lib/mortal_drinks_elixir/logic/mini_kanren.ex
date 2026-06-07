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

  @doc """
  Committed-choice cond: 每个 clause 的第一个 goal 是 guard。
  一旦 guard 成功，commit 到 body，跳过其余 clause。
  """
  defmacro condu(do: block) do
    clauses =
      case block do
        {:__block__, _, lines} -> lines
        single -> [single]
      end

    build_condu(clauses)
  end

  defp build_condu([]) do
    quote do: Core.mzero()
  end

  defp build_condu([[guard | body] | rest]) do
    body_goal = conjoin_clause(body)
    quote do
      Core.ifte(
        unquote(guard),
        unquote(body_goal),
        unquote(build_condu(rest))
      )
    end
  end

  @doc """
  Pattern-matching cond (Reasoned Schemer style):

      matche [x, y] do
        [:a, b] -> eq(b, 1)
        [a, :b] -> eq(a, 2)
      end

  模式中的 atom（`:a`）是字面量，小写标识符（`b`）是隐式 fresh 变量。
  """
  defmacro matche(subject, do: block) do
    clauses =
      case block do
        {:__block__, _, lines} -> lines
        [{:->, _, _} | _] = list -> list
        single -> [single]
      end

    build_matche(subject, clauses)
  end

  defp build_matche(subject, clauses) do
    clause_goals =
      Enum.map(clauses, fn
        {:->, _, [patterns, body]} ->
          [pattern] = patterns
          build_pattern_clause(subject, pattern, body)
      end)

    disjoin_all(clause_goals)
  end

  defp build_pattern_clause(subject, pattern, body) do
    fresh_vars = collect_pattern_vars(pattern) |> Enum.uniq_by(&elem(&1, 0))

    # 生成 eq(subject_i, pattern_i) 的目标
    unify_goals =
      case {subject, pattern} do
        {list_s, list_p} when is_list(list_s) and is_list(list_p) ->
          Enum.zip(list_s, list_p)
          |> Enum.map(fn {s, p} -> quote do: eq(unquote(s), unquote(p)) end)
        _ ->
          [quote do: eq(unquote(subject), unquote(pattern))]
      end

    all_goals = unify_goals ++ [body]

    # 用 call_fresh 嵌套——直接用 pattern 中的 AST 节点，保证变量绑定一致
    Enum.reduce(fresh_vars, conjoin_clause(all_goals), fn var_ast, acc ->
      quote do
        Core.call_fresh(fn unquote(var_ast) -> unquote(acc) end)
      end
    end)
  end

  # 从模式中提取隐式变量（小写标识符 = AST 中的 {name, _, _} 三元组）
  # 返回完整 AST 节点，保证与 body 中的引用是同一变量
  defp collect_pattern_vars({name, meta, ctx}) when is_atom(name) do
    [{name, meta, ctx}]
  end

  defp collect_pattern_vars(list) when is_list(list) do
    Enum.flat_map(list, &collect_pattern_vars/1)
  end

  defp collect_pattern_vars(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.flat_map(&collect_pattern_vars/1)
  end

  defp collect_pattern_vars(_), do: []

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
  defdelegate run(n, arity, f), to: Core
  defdelegate run_all(f), to: Core

  @doc "`symbolo(x)`: x 必须是 atom。"
  @spec symbolo(Core.Var.maybe_term()) :: Core.goal()
  def symbolo(x) do
    typeo(x, :symbol)
  end

  @doc "`numbero(x)`: x 必须是 number。"
  @spec numbero(Core.Var.maybe_term()) :: Core.goal()
  def numbero(x) do
    typeo(x, :number)
  end

  defp typeo(x, kind) do
    fn %Core.State{subst: s, constraints: cs} = state ->
      x_w = Core.walk_star(x, s)

      cond do
        Core.Var.var?(x_w) ->
          Core.unit(%{state | constraints: [{:type, x, kind} | cs]})

        kind == :symbol and is_atom(x_w) ->
          Core.unit(state)

        kind == :number and is_number(x_w) ->
          Core.unit(state)

        true ->
          Core.mzero()
      end
    end
  end

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

  存储在 `state.constraints` 中，每次 unify 成功后检查。
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
