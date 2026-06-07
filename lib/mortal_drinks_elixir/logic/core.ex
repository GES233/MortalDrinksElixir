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
      def to_string(%{id: id}), do: "_#{id}"
    end
  end

  defmodule State do
    @moduledoc """
    状态结构体。

    * `subst`: 替换表
    * `counter`: 用于生成新逻辑变量的计数器
    * `pid`: 接收遥测进程的 PID
    * `extension`: 用于扩展（e.g. miniKanren 的 constraints）
    """
    # 针对 extension 的操作用 get_in/pit_in 来吧

    @type substitution :: %{Var.t() => term()}

    @type t :: %__MODULE__{
            subst: substitution(),
            counter: non_neg_integer(),
            pid: pid() | nil,
            extension: %{atom() => term()}
          }
    defstruct subst: %{}, counter: 0, pid: nil, extension: %{}
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
  def unify(u, v, %State{subst: s, pid: pid} = state) do
    result = unify_terms(u, v, s)

    if pid do
      status = if result, do: :ok, else: :fail
      send(pid, {:logic_trace, status, u, v})
    end

    case result do
      nil -> nil
      new_subst -> %{state | subst: new_subst}
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

  # --- Tookit ---

  # 深度 walk
  def walk_star(v, s) do
    v = walk(v, s)

    cond do
      Var.var?(v) ->
        v

      is_list(v) -> walk_star_list(v, s)

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

  # run：引入查询变量 q，跑 n 个答案
  def run(n, f) do
    goal = call_fresh(f)

    goal.(%State{})
    |> take(n)
    |> Enum.map(&reify(%Var{id: 0}, &1))
  end

  def run_all(f) do
    call_fresh(f).(%State{}) |> take_all() |> Enum.map(&reify(%Var{id: 0}, &1))
  end
end
