defmodule MortalDrinksElixir.Logic.Core do
  @moduledoc """
  附带 occurs-check 以及 fair-search 的 microKanren 实现。
  """

  # --- 数据结构 ---

  defmodule Var do
    @moduledoc "逻辑变量。"

    @type t :: %__MODULE__{id: integer()}
    @type maybe_term :: t() | term()

    defstruct [:id]

    def var?(%__MODULE__{}), do: true
    def var?(_), do: false

    # 为了让日志更好看，实现 String.Chars 协议
    defimpl String.Chars do
      def to_string(%{id: id}), do: "?#{id}"
    end
  end

  defmodule State do
    @moduledoc """
    状态结构体。

    * `subst`: 替换表
    * `counter`: 用于生成新逻辑变量的计数器
    * `pid`: 接收遥测进程的 PID
    * `constraints`: 一系列的约束
    * `extension`: 用于扩展
    """

    # 针对 extension 的操作用 get_in/put_in 来吧

    @type substitution :: %{Var.t() => term()}
    @type constraint_type :: atom()
    @type constraint :: {constraint_type(), Var.maybe_term(), Var.maybe_term()}

    @type t :: %__MODULE__{
            subst: substitution(),
            counter: non_neg_integer(),
            pid: pid() | nil,
            constraints: [constraint()],
            extension: %{atom() => term()}
          }
    defstruct subst: %{}, counter: 0, pid: nil, constraints: [], extension: %{}
  end

  # --- 核心操作 ---

  def walk(%Var{} = u, subst) do
    case Map.fetch(subst, u) do
      {:ok, v} -> walk(v, subst)
      :error -> u
    end
  end

  def walk(u, _), do: u

  @spec unify(Var.maybe_term(), Var.maybe_term(), State.t()) ::
          nil | State.t()
  def unify(u, v, %State{subst: s, constraints: cs, pid: pid} = state) do
    result = unify_terms(u, v, s)

    if pid do
      status = if result, do: :ok, else: :fail
      send(pid, {:logic_trace, status, u, v})
    end

    case result do
      nil ->
        nil

      new_subst ->
        if check_constraints(new_subst, cs) do
          %{state | subst: new_subst}
        else
          nil
        end
    end
  end

  defp unify_terms(u, v, s) do
    u = walk(u, s)
    v = walk(v, s)

    cond do
      u == v ->
        s

      Var.var?(u) ->
        ext_s(u, v, s)

      Var.var?(v) ->
        ext_s(v, u, s)

      is_list(u) and is_list(v) ->
        unify_lists(u, v, s)

      is_tuple(u) and is_tuple(v) and tuple_size(u) == tuple_size(v) ->
        unify_terms(Tuple.to_list(u), Tuple.to_list(v), s)

      true ->
        nil
    end
  end

  defp unify_lists([], [], s), do: s

  defp unify_lists([u | us], [v | vs], s) do
    case unify_terms(u, v, s) do
      nil -> nil
      s_prime -> unify_terms(us, vs, s_prime)
    end
  end

  defp unify_lists(_, _, _), do: nil

  defp ext_s(u, v, s) do
    if occurs?(u, v, s) do
      nil
    else
      Map.put(s, u, v)
    end
  end

  defp occurs?(x, v, s) do
    v = walk(v, s)

    cond do
      x == v ->
        true

      Var.var?(v) ->
        false

      is_list(v) ->
        occurs_list?(x, v, s)

      is_tuple(v) ->
        v
        |> Tuple.to_list()
        |> Enum.any?(fn elem -> occurs?(x, elem, s) end)

      true ->
        false
    end
  end

  defp occurs_list?(_x, [], _s), do: false

  defp occurs_list?(x, [h | t], s) do
    occurs?(x, h, s) or occurs?(x, t, s)
  end

  defp occurs_list?(_x, _non_list_tail, _s), do: false

  defp absento_holds?(_sym, %Var{}), do: true

  defp absento_holds?(sym, term) do
    cond do
      term == sym -> false
      is_list(term) -> Enum.all?(term, &absento_holds?(sym, &1))
      is_tuple(term) -> term |> Tuple.to_list() |> Enum.all?(&absento_holds?(sym, &1))
      true -> true
    end
  end

  defp check_constraints(_subst, []), do: true

  defp check_constraints(subst, [{:type, x, kind} | rest]) do
    x_w = walk_star(x, subst)
    type_ok =
      cond do
        Var.var?(x_w) -> true
        kind == :symbol -> is_atom(x_w)
        kind == :number -> is_number(x_w)
        true -> false
      end
    type_ok and check_constraints(subst, rest)
  end

  defp check_constraints(subst, [{:diseq, u, v} | rest]) do
    walk_star(u, subst) != walk_star(v, subst) and check_constraints(subst, rest)
  end

  defp check_constraints(subst, [{:absento, sym, x} | rest]) do
    x_w = walk_star(x, subst)
    absento_holds?(sym, x_w) and check_constraints(subst, rest)
  end

  defp check_constraints(subst, [_unknown | rest]) do
    check_constraints(subst, rest)
  end

  @doc "if-then-else: 如果 g 成功则 commit 到 th，否则 el。不回溯 g 的其他解。"
  @spec ifte(goal(), goal(), goal()) :: goal()
  def ifte(g, th, el) do
    fn %State{} = state ->
      case pull(g.(state)) do
        [] -> el.(state)
        {:mature, h, _} -> th.(h)
      end
    end
  end

  @doc "只取 goal 的第一个解。"
  @spec once(goal()) :: goal()
  def once(g) do
    fn %State{} = state ->
      case pull(g.(state)) do
        [] -> []
        {:mature, h, _} -> unit(h)
      end
    end
  end

  # --- 一些搜索策略之类的 ---

  @type stream :: [] | {:mature, State.t(), stream()} | {:immature, (-> stream())}
  @type goal :: (State.t() -> stream())

  @spec mzero :: stream()
  def mzero, do: []

  @spec unit(State.t()) :: stream()
  def unit(%State{} = state), do: {:mature, state, []}

  @spec mplus(stream(), stream()) :: stream()
  def mplus([], s2), do: s2
  def mplus({:immature, f}, s2), do: {:immature, fn -> mplus(s2, f.()) end}
  def mplus({:mature, h, t}, s2), do: {:mature, h, mplus(t, s2)}

  @spec bind(stream(), goal()) :: stream()
  def bind([], _g), do: []
  def bind({:immature, f}, g), do: {:immature, fn -> bind(f.(), g) end}
  def bind({:mature, h, t}, g), do: mplus(g.(h), bind(t, g))

  # --- Goals (Constructors) ---

  @spec eq(Var.maybe_term(), Var.maybe_term()) :: goal()
  def eq(u, v) do
    fn %State{} = state ->
      case unify(u, v, state) do
        nil -> mzero()
        new_state -> unit(new_state)
      end
    end
  end

  @spec conj(goal(), goal()) :: goal()
  def conj(g1, g2) do
    fn %State{} = state -> bind(g1.(state), g2) end
  end

  @spec disj(goal(), goal()) :: goal()
  def disj(g1, g2) do
    fn %State{} = state -> mplus(g1.(state), g2.(state)) end
  end

  # 负责将 goal 的求值推迟
  @spec delay((-> goal())) :: goal()
  def delay(goal_fun) do
    fn %State{} = state -> {:immature, fn -> goal_fun.().(state) end} end
  end

  # 把流推进到 mature 或 [] 为止
  defp pull([]), do: []
  defp pull({:immature, f}), do: pull(f.())
  defp pull({:mature, _, _} = s), do: s

  def take(_stream, 0), do: []

  def take(stream, n) do
    case pull(stream) do
      [] -> []
      {:mature, h, t} -> [h | take(t, n - 1)]
    end
  end

  def take_all(stream) do
    case pull(stream) do
      [] -> []
      {:mature, h, t} -> [h | take_all(t)]
    end
  end

  # call_fresh 负责引入逻辑变量
  def call_fresh(f) do
    fn %State{counter: c} = s ->
      # 1. 创建新变量
      v = %Var{id: c}
      # 2. 获取用户闭包中的 Goal (f.(v) 返回的是 Goal)
      goal = f.(v)
      # 3. 更新计数器
      new_state = %{s | counter: c + 1}
      # 4. === 关键修正 ===
      # 必须在这里调用 goal 并传入 state，才能返回 Stream
      goal.(new_state)
    end
  end

  # --- Toolkit ---

  # 深度 walk
  def walk_star(v, s) do
    v = walk(v, s)

    cond do
      Var.var?(v) ->
        v

      is_list(v) ->
        walk_star_list(v, s)

      is_tuple(v) ->
        v |> Tuple.to_list() |> Enum.map(&walk_star(&1, s)) |> List.to_tuple()

      true ->
        v
    end
  end

  defp walk_star_list([], _s), do: []
  defp walk_star_list([h | t], s), do: [walk_star(h, s) | walk_star(t, s)]

  # 把变量重命名成 _0, _1 ...
  defp reify_s(v, s) do
    v = walk(v, s)

    cond do
      Var.var?(v) -> Map.put(s, v, :"_#{map_size(s)}")
      is_list(v) -> reify_s_list(v, s)
      is_tuple(v) -> v |> Tuple.to_list() |> Enum.reduce(s, &reify_s/2)
      true -> s
    end
  end

  defp reify_s_list([], s), do: s
  defp reify_s_list([h | t], s), do: reify_s(t, reify_s(h, s))

  def reify(var, %State{subst: s}) do
    walked = walk_star(var, s)
    walk_star(walked, reify_s(walked, %{}))
  end

  @doc """
  带约束的 reify：返回 `{value, residual_constraints}`。

  constraints 中被 reify 过（Var → :_N 重命名），
  只保留涉及查询变量的约束。
  """
  def reify_with_constraints(vars, %State{subst: s, constraints: cs})
      when is_list(vars) do
    # 先跑正常的 reify 拿到答案
    values =
      Enum.map(vars, fn var ->
        walked = walk_star(var, s)
        walk_star(walked, reify_s(walked, %{}))
      end)

    # 过滤约束：只保留涉及这些 var 的
    var_ids = MapSet.new(vars, & &1.id)
    reified_cs =
      cs
      |> Enum.filter(fn
        {:diseq, u, v} -> involves_any?(u, s, var_ids) or involves_any?(v, s, var_ids)
        {:absento, _sym, x} -> involves_any?(x, s, var_ids)
        {:type, x, _kind} -> involves_any?(x, s, var_ids)
        _ -> false
      end)
      |> Enum.map(&reify_constraint(&1, s))

    {values, reified_cs}
  end

  defp involves_any?(%Var{id: id}, _s, var_ids), do: MapSet.member?(var_ids, id)
  defp involves_any?(term, s, var_ids) when is_list(term) do
    Enum.any?(term, &involves_any?(&1, s, var_ids))
  end
  defp involves_any?(term, s, var_ids) when is_tuple(term) do
    term |> Tuple.to_list() |> Enum.any?(&involves_any?(&1, s, var_ids))
  end
  defp involves_any?(_term, _s, _var_ids), do: false

  defp reify_constraint({:diseq, u, v}, s) do
    u_w = walk_star(u, s)
    v_w = walk_star(v, s)
    rm = reify_s(u_w, reify_s(v_w, %{}))
    {:diseq, walk_star(u_w, rm), walk_star(v_w, rm)}
  end

  defp reify_constraint({:absento, sym, x}, s) do
    x_w = walk_star(x, s)
    rm = reify_s(x_w, %{})
    {:absento, sym, walk_star(x_w, rm)}
  end

  defp reify_constraint({:type, x, kind}, s) do
    x_w = walk_star(x, s)
    rm = reify_s(x_w, %{})
    {:type, walk_star(x_w, rm), kind}
  end

  # run：引入查询变量 q，跑 n 个答案
  def run(n, f) do
    q = %Var{id: 0}

    f.(q).(%State{counter: 1})
    |> take(n)
    |> Enum.map(&reify(q, &1))
  end

  def run_all(f) do
    call_fresh(f).(%State{}) |> take_all() |> Enum.map(&reify(%Var{id: 0}, &1))
  end

  @doc """
  多变量查询：`run(n, arity, fn [a, b, c] -> goal end)` 或 `fn {a, b} -> goal end`

  返回对应形状的 tuple。
  """
  def run(n, arity, f) when is_integer(arity) and arity > 0 do
    goal = build_fresh_chain(arity, [], f)

    goal.(%State{})
    |> take(n)
    |> Enum.map(fn state ->
      Enum.map(0..(arity - 1), fn i ->
        reify(%Var{id: i}, state)
      end)
      |> List.to_tuple()
    end)
  end

  defp build_fresh_chain(0, collected, f) do
    f.(Enum.reverse(collected))
  end

  defp build_fresh_chain(n, collected, f) do
    call_fresh(fn v ->
      build_fresh_chain(n - 1, [v | collected], f)
    end)
  end
end
