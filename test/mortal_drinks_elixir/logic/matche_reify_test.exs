defmodule MortalDrinksElixir.Logic.MatcheReifyTest do
  use ExUnit.Case, async: false

  alias MortalDrinksElixir.Logic.{Core, MiniKanren, Relations}
  import MiniKanren

  # ============================================================
  # matche
  # ============================================================

  describe "matche" do
    test "literal matching" do
      results = run(1, fn q ->
        matche q do
          :a -> eq(q, :a)
        end
      end)
      assert results == [:a]
    end

    test "two-branch match" do
      results = run(2, fn q ->
        matche q do
          :a -> eq(q, :a)
          :b -> eq(q, :b)
        end
      end)
      assert Enum.sort(results) == [:a, :b]
    end

    test "list pattern with implicit fresh var" do
      results = run(1, fn q ->
        matche q do
          [:a, x] -> eq(q, [:a, x])
        end
      end)
      assert results == [[:a, :_0]]
    end

    test "nested list pattern" do
      results = run(1, fn q ->
        matche q do
          [[x, y], z] -> eq([x, y, z], [1, 2, 3])
        end
      end)
      assert results == [[[1, 2], 3]]
    end

    test "tuple pattern" do
      results = run(1, fn q ->
        matche q do
          {:ok, val} -> eq(q, {:ok, val})
        end
      end)
      assert results == [{:ok, :_0}]
    end
  end

  # ============================================================
  # reify_with_constraints
  # ============================================================

  describe "reify_with_constraints" do
    test "no constraints → empty constraint list" do
      goal = eq(%Core.Var{id: 0}, 42)
      [state | _] = goal.(%Core.State{}) |> Core.take(1)
      {values, cs} = Core.reify_with_constraints([%Core.Var{id: 0}], state)
      assert values == [42]
      assert cs == []
    end

    test "diseq constraint appears in output" do
      goal =
        Core.call_fresh(fn q ->
          Core.conj(Core.eq(q, 42), diseq(q, 99))
        end)

      [state | _] = goal.(%Core.State{}) |> Core.take(1)
      {values, cs} = Core.reify_with_constraints([%Core.Var{id: 0}], state)
      assert values == [42]
      assert {:diseq, 42, 99} in cs
    end

    test "absento constraint appears in output" do
      goal =
        Core.call_fresh(fn q ->
          Core.conj(Core.eq(q, :hello), absento(:bad, :hello))
        end)

      [state | _] = goal.(%Core.State{}) |> Core.take(1)
      {values, cs} = Core.reify_with_constraints([%Core.Var{id: 0}], state)
      assert values == [:hello]
      # absento(:bad, :hello) — ground value, no residual constraint
      assert cs == []
    end

    test "unbound var with diseq" do
      goal =
        Core.call_fresh(fn q ->
          diseq(q, 99)
        end)

      [state | _] = goal.(%Core.State{}) |> Core.take(1)
      {values, cs} = Core.reify_with_constraints([%Core.Var{id: 0}], state)
      assert values == [:_0]
      assert {:diseq, :_0, 99} in cs
    end

    test "type constraint in output" do
      goal =
        Core.call_fresh(fn q ->
          Core.conj(Core.eq(q, 42), numbero(q))
        end)

      [state | _] = goal.(%Core.State{}) |> Core.take(1)
      {values, cs} = Core.reify_with_constraints([%Core.Var{id: 0}], state)
      # type constr satisfied by ground value → no residual
      assert cs == []
    end
  end
end
