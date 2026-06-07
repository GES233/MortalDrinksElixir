defmodule MortalDrinksElixir.Logic.CoreTest do
  use ExUnit.Case, async: true

  alias MortalDrinksElixir.Logic.Core
  alias MortalDrinksElixir.Logic.Core.{Var, State}

  # ============================================================
  # Var
  # ============================================================

  describe "Var" do
    test "var?/1 recognises Var struct" do
      assert Var.var?(%Var{id: 0})
      refute Var.var?(42)
      refute Var.var?("hello")
      refute Var.var?(%{id: 0})
    end

    test "String.Chars protocol" do
      assert to_string(%Var{id: 3}) == "_3"
    end
  end

  # ============================================================
  # walk
  # ============================================================

  describe "walk/2" do
    test "non-variable term returns itself" do
      assert Core.walk(42, %{}) == 42
      assert Core.walk(:foo, %{}) == :foo
      assert Core.walk([1, 2], %{}) == [1, 2]
    end

    test "unbound variable returns itself" do
      x = %Var{id: 0}
      assert Core.walk(x, %{}) == x
    end

    test "bound variable returns its value" do
      x = %Var{id: 0}
      assert Core.walk(x, %{x => 42}) == 42
    end

    test "transitive walk: x -> y -> value" do
      x = %Var{id: 0}
      y = %Var{id: 1}
      subst = %{x => y, y => 99}
      assert Core.walk(x, subst) == 99
    end
  end

  # ============================================================
  # unify
  # ============================================================

  describe "unify/3" do
    test "identical atoms succeed" do
      state = %State{}
      assert %State{subst: %{}} = Core.unify(:a, :a, state)
    end

    test "different atoms fail" do
      assert nil == Core.unify(:a, :b, %State{})
    end

    test "integer equality" do
      assert %State{} = Core.unify(1, 1, %State{})
      assert nil == Core.unify(1, 2, %State{})
    end

    test "unify variable with value extends subst" do
      x = %Var{id: 0}
      result = Core.unify(x, :hello, %State{})
      assert result != nil
      assert result.subst[x] == :hello
    end

    test "unify value with variable extends subst" do
      x = %Var{id: 0}
      result = Core.unify(:hello, x, %State{})
      assert result != nil
      assert result.subst[x] == :hello
    end

    test "unify two variables extends subst" do
      x = %Var{id: 0}
      y = %Var{id: 1}
      result = Core.unify(x, y, %State{})
      assert result != nil
      assert result.subst[x] == y
    end

    test "unify same variable succeeds (no extension)" do
      x = %Var{id: 0}
      state = %State{subst: %{x => 42}}
      result = Core.unify(x, x, state)
      assert result != nil
    end

    test "list unification element-wise" do
      result = Core.unify([1, 2, 3], [1, 2, 3], %State{})
      assert result != nil
    end

    test "list unification fails on mismatch" do
      assert nil == Core.unify([1, 2], [1, 3], %State{})
    end

    test "list unification with different lengths fails" do
      assert nil == Core.unify([1, 2], [1, 2, 3], %State{})
    end

    test "list with variable" do
      x = %Var{id: 0}
      result = Core.unify([1, x, 3], [1, 2, 3], %State{})
      assert result != nil
      assert result.subst[x] == 2
    end

    test "tuple unification" do
      result = Core.unify({:a, 1}, {:a, 1}, %State{})
      assert result != nil
    end

    test "tuple size mismatch fails" do
      assert nil == Core.unify({:a, 1}, {:a, 1, 2}, %State{})
    end

    test "tuple with variable" do
      x = %Var{id: 0}
      result = Core.unify({:ok, x}, {:ok, :bar}, %State{})
      assert result != nil
      assert result.subst[x] == :bar
    end

    test "mixed types fail" do
      assert nil == Core.unify(:a, 1, %State{})
      assert nil == Core.unify([1], {1}, %State{})
    end
  end

  # ============================================================
  # occurs-check
  # ============================================================

  describe "occurs-check" do
    test "unify(x, [x]) fails — cyclic" do
      x = %Var{id: 0}
      result = Core.unify(x, [x], %State{})
      assert result == nil
    end

    test "unify(x, {x}) fails — cyclic tuple" do
      x = %Var{id: 0}
      assert nil == Core.unify(x, {x}, %State{})
    end

    test "unify(x, [1, [x]]) fails — nested cyclic" do
      x = %Var{id: 0}
      assert nil == Core.unify(x, [1, [x]], %State{})
    end
  end

  # ============================================================
  # Stream & Search
  # ============================================================

  describe "mzero/0 and unit/1" do
    test "mzero is empty list" do
      assert Core.mzero() == []
    end

    test "unit wraps state in mature tuple" do
      s = %State{}
      assert {:mature, ^s, []} = Core.unit(s)
    end
  end

  describe "take/2" do
    test "take 0 returns []" do
      assert Core.take(Core.mzero(), 0) == []
    end

    test "take from empty stream" do
      assert Core.take(Core.mzero(), 5) == []
    end
  end

  # ============================================================
  # Goals: eq, conj, disj
  # ============================================================

  describe "eq/2 goal" do
    test "eq succeeds for identical values" do
      goal = Core.eq(:a, :a)
      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 1
    end

    test "eq fails for different values" do
      goal = Core.eq(:a, :b)
      results = goal.(%State{}) |> Core.take(5)
      assert results == []
    end
  end

  describe "conj/2" do
    test "both succeed" do
      goal = Core.conj(Core.eq(:a, :a), Core.eq(:b, :b))
      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 1
    end

    test "first fails" do
      goal = Core.conj(Core.eq(:a, :b), Core.eq(:c, :c))
      results = goal.(%State{}) |> Core.take(5)
      assert results == []
    end

    test "second fails" do
      goal = Core.conj(Core.eq(:a, :a), Core.eq(:b, :c))
      results = goal.(%State{}) |> Core.take(5)
      assert results == []
    end
  end

  describe "disj/2" do
    test "first succeeds" do
      goal = Core.disj(Core.eq(:a, :a), Core.eq(:a, :b))
      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 1
    end

    test "second succeeds" do
      goal = Core.disj(Core.eq(:a, :b), Core.eq(:a, :a))
      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 1
    end

    test "both succeed yields two results" do
      x = %Var{id: 0}
      goal = Core.disj(Core.eq(x, :a), Core.eq(x, :b))
      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 2
    end

    test "neither succeeds" do
      goal = Core.disj(Core.eq(:a, :b), Core.eq(:c, :d))
      results = goal.(%State{}) |> Core.take(5)
      assert results == []
    end
  end

  # ============================================================
  # call_fresh
  # ============================================================

  describe "call_fresh/1" do
    test "introduces a logic variable and runs the goal" do
      goal =
        Core.call_fresh(fn x ->
          Core.eq(x, 42)
        end)

      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 1
    end

    test "counter increments" do
      goal =
        Core.call_fresh(fn _x ->
          Core.call_fresh(fn _y ->
            Core.eq(:ok, :ok)
          end)
        end)

      [state | _] = goal.(%State{}) |> Core.take(5)
      assert state.counter == 2
    end
  end

  # ============================================================
  # reify / walk_star
  # ============================================================

  describe "reify/2" do
    test "reify bound variable gives the value" do
      x = %Var{id: 0}
      state = %State{subst: %{x => 42}}
      assert Core.reify(x, state) == 42
    end

    test "reify unbound variable gives :_0" do
      x = %Var{id: 0}
      assert Core.reify(x, %State{}) == :_0
    end

    test "reify list with unbound variable" do
      x = %Var{id: 0}
      state = %State{subst: %{x => :hello}}
      assert Core.reify([x, :world], state) == [:hello, :world]
    end

    test "reify nested list with two unbound vars gives :_0 :_1" do
      x = %Var{id: 0}
      y = %Var{id: 1}
      result = Core.reify([x, y], %State{})
      assert result == [:_0, :_1]
    end

    test "reify tuple" do
      x = %Var{id: 0}
      state = %State{subst: %{x => :ok}}
      assert Core.reify({:tag, x}, state) == {:tag, :ok}
    end
  end

  # ============================================================
  # run / run_all — top-level API
  # ============================================================

  describe "run/2" do
    test "simple eq — q unify with 5" do
      results = Core.run(1, fn q -> Core.eq(q, 5) end)
      assert results == [5]
    end

    test "disj — q is :a or :b" do
      results = Core.run(10, fn q -> Core.disj(Core.eq(q, :a), Core.eq(q, :b)) end)
      assert Enum.sort(results) == [:a, :b]
    end

    test "run 0 returns []" do
      assert Core.run(0, fn q -> Core.eq(q, 1) end) == []
    end

    test "unification failure" do
      assert Core.run(5, fn _q -> Core.eq(:a, :b) end) == []
    end

    test "chained conj" do
      results =
        Core.run(5, fn q ->
          Core.conj(Core.eq(q, :x), Core.eq(q, :x))
        end)

      assert results == [:x]
    end

    test "conj with conflicting eq fails" do
      results =
        Core.run(5, fn q ->
          Core.conj(Core.eq(q, :a), Core.eq(q, :b))
        end)

      assert results == []
    end

    test "conj with nested fresh vars" do
      results =
        Core.run(1, fn q ->
          Core.call_fresh(fn x ->
            Core.conj(Core.eq(x, 10), Core.eq(q, x))
          end)
        end)

      assert results == [10]
    end
  end

  describe "run_all/1" do
    test "finite disj returns all" do
      results =
        Core.run_all(fn q ->
          Core.disj(Core.eq(q, :a), Core.eq(q, :b))
        end)

      assert Enum.sort(results) == [:a, :b]
    end
  end

  # ============================================================
  # Fair interleaving — delay + disj
  # ============================================================

  describe "delay/1 for fair search" do
    test "delay produces immature stream that resolves on pull" do
      goal =
        Core.delay(fn ->
          Core.eq(:a, :a)
        end)

      stream = goal.(%State{})
      assert {:immature, f} = stream
      resolved = f.()
      assert {:mature, _, _} = resolved
    end

    test "disj with delay interleaves correctly" do
      goal =
        Core.disj(
          Core.delay(fn -> Core.eq(:a, :a) end),
          Core.eq(:b, :b)
        )

      results = goal.(%State{}) |> Core.take(5)
      assert length(results) == 2
    end
  end

  # ============================================================
  # Integration: classic miniKanren examples
  # ============================================================

  describe "classic miniKanren: fives" do
    test "fives(x) produces 5 repeatedly (take finite)" do
      fives = fn fives ->
        fn x ->
          Core.disj(
            Core.eq(x, 5),
            Core.delay(fn -> fives.(fives).(x) end)
          )
        end
      end

      results =
        Core.run(3, fn q ->
          fives.(fives).(q)
        end)

      assert results == [5, 5, 5]
    end
  end

  describe "unify with nested structures" do
    test "deeply nested list unification" do
      results =
        Core.run(1, fn q ->
          Core.eq(q, [[1, 2], [3, [4, 5]]])
        end)

      assert results == [[[1, 2], [3, [4, 5]]]]
    end

    test "nested tuples" do
      results =
        Core.run(1, fn q ->
          Core.eq(q, {:a, {:b, :c}})
        end)

      assert results == [{:a, {:b, :c}}]
    end
  end

  describe "multiple fresh variables" do
    test "introduce 3 fresh vars and constrain" do
      results =
        Core.run(1, fn q ->
          Core.call_fresh(fn a ->
            Core.call_fresh(fn b ->
              Core.call_fresh(fn c ->
                Core.conj(
                  Core.eq(a, 1),
                  Core.conj(
                    Core.eq(b, 2),
                    Core.conj(
                      Core.eq(c, 3),
                      Core.eq(q, [a, b, c])
                    )
                  )
                )
              end)
            end)
          end)
        end)

      assert results == [[1, 2, 3]]
    end
  end

  # ============================================================
  # Telemetry / pid tracing
  # ============================================================

  describe "unify with pid tracing" do
    test "sends :logic_trace on success" do
      state = %State{pid: self()}
      _result = Core.unify(:a, :a, state)
      assert_receive {:logic_trace, :ok, :a, :a}
    end

    test "sends :logic_trace on failure" do
      state = %State{pid: self()}
      _result = Core.unify(:a, :b, state)
      assert_receive {:logic_trace, :fail, :a, :b}
    end

    test "does not send when pid is nil" do
      state = %State{pid: nil}
      _result = Core.unify(:a, :a, state)
      refute_receive {:logic_trace, _, _, _}
    end
  end
end
