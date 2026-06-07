defmodule MortalDrinksElixir.Logic.Relations do
  @moduledoc "miniKanren 关系库：conso / caro / cdro / nullo / pairo / appendo / membero / listo"

  alias MortalDrinksElixir.Logic.Core

  # --- 基础关系 ---

  @doc "p = [a | d]，任意方向。"
  @spec conso(Core.Var.maybe_term(), Core.Var.maybe_term(), Core.Var.maybe_term()) :: Core.goal()
  def conso(a, d, p) do
    Core.eq([a | d], p)
  end

  @doc "a = hd(p)。"
  @spec caro(Core.Var.maybe_term(), Core.Var.maybe_term()) :: Core.goal()
  def caro(p, a) do
    Core.call_fresh(fn d ->
      Core.eq([a | d], p)
    end)
  end

  @doc "d = tl(p)。"
  @spec cdro(Core.Var.maybe_term(), Core.Var.maybe_term()) :: Core.goal()
  def cdro(p, d) do
    Core.call_fresh(fn a ->
      Core.eq([a | d], p)
    end)
  end

  @doc "l == []。"
  @spec nullo(Core.Var.maybe_term()) :: Core.goal()
  def nullo(l) do
    Core.eq(l, [])
  end

  @doc "p 是非空 list（cons pair）。"
  @spec pairo(Core.Var.maybe_term()) :: Core.goal()
  def pairo(p) do
    Core.call_fresh(fn a ->
      Core.call_fresh(fn d ->
        Core.eq(p, [a | d])
      end)
    end)
  end

  # --- 递归关系 ---

  @doc """
  递归追加：out = l ++ r。

  使用 delay 防止无限展开。
  """
  def appendo(l, r, out) do
    Core.delay(fn ->
      Core.disj(
        # l 为空：out = r
        Core.conj(nullo(l), Core.eq(r, out)),
        # l 非空：分解 l，递归，重组
        Core.call_fresh(fn a ->
          Core.call_fresh(fn d ->
            Core.call_fresh(fn res ->
              Core.conj(cdro(l, d),
                Core.conj(caro(l, a),
                  Core.conj(appendo(d, r, res),
                    Core.eq([a | res], out))))
            end)
          end)
        end)
      )
    end)
  end

  @doc """
  x 是 l 的成员。
  """
  def membero(x, l) do
    Core.delay(fn ->
      Core.call_fresh(fn a ->
        Core.call_fresh(fn d ->
          Core.conj(caro(l, a),
            Core.disj(
              Core.eq(x, a),
              Core.conj(cdro(l, d), membero(x, d))
            ))
        end)
      end)
    end)
  end

  @doc """
  l 是 proper list（空或 cons 且 tail 是 proper list）。
  """
  def listo(l) do
    Core.delay(fn ->
      Core.disj(
        nullo(l),
        Core.call_fresh(fn a ->
          Core.call_fresh(fn d ->
            Core.conj(Core.eq(l, [a | d]), listo(d))
          end)
        end)
      )
    end)
  end
end
