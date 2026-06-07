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
    """

    @type substitution :: %{Var.t() => term()}

    @type t :: %__MODULE__{
            subst: substitution(),
            counter: non_neg_integer(),
            pid: pid() | nil
          }
    defstruct subst: %{}, counter: 0, pid: nil
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

  # mzero
  # unit
  # mplus
  # bind

  # --- Goals (Constructors) ---

  # eq 返回一个 Goal (fn state -> stream)
  def eq(u, v) do
    fn state ->
      case unify(u, v, state) do
        # 失败返回空流
        nil -> []
        # 成功返回包含新状态的流
        new_state -> [new_state]
      end
    end
  end

  # conj 返回一个 Goal
  # 它执行 g1，得到状态流，然后对流中的每个状态执行 g2
  def conj(g1, g2) do
    fn state ->
      state
      # 执行第一个目标
      |> g1.()
      # 将结果流传递给第二个目标
      |> Stream.flat_map(g2)
    end
  end

  # Where's disj?
  def disj(g1, g2) do
    fn state ->
      Stream.concat(g1.(state), g2.(state))
      # 更严格的实现应该用 interleaving (mplus)
      # 以避免无限流吞掉另一个分支
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

  # delay

  # --- Tookit ---
  # reify
  # run
end
