defmodule MortalDrinksElixir.Logic.DiseqTest do
  use ExUnit.Case, async: false

  alias MortalDrinksElixir.Logic.{Core, MiniKanren, Relations}
  import MiniKanren

  # ============================================================
  # Basic =/=
  # ============================================================

  describe "immediate failure" do
    test "=/=(x, x) fails" do
      results = run(1, fn q ->
        fresh x do
          Core.conj(eq(q, :ok), diseq(x, x))
        end
      end)
      assert results == []
    end

    test "=/=(5, 5) fails" do
      results = run(1, fn _q -> diseq(5, 5) end)
      assert results == []
    end

    test "=/=(x, y) with distinct vars succeeds" do
      results = run(1, fn _ ->
        fresh [x, y] do
          diseq(x, y)
        end
      end)
      assert length(results) == 1
    end
  end

  # ============================================================
  # =/= with unify
  # ============================================================

  describe "=/= blocks unification" do
    test "x =/= 5 then eq(x, 5) fails" do
      results = run(1, fn q ->
        fresh x do
          Core.conj(
            diseq(x, 5),
            Core.conj(eq(x, 5), eq(q, :fail))
          )
        end
      end)
      assert results == []
    end

    test "x =/= 5, eq(x, 3) succeeds" do
      results = run(1, fn q ->
        fresh x do
          Core.conj(
            diseq(x, 5),
            Core.conj(eq(x, 3), eq(q, x))
          )
        end
      end)
      assert results == [3]
    end

    test "diseq then eq with different var" do
      results = run(1, fn q ->
        fresh [x, y] do
          Core.conj(
            diseq(x, 5),
            Core.conj(eq(y, 5), eq(q, [x, y]))
          )
        end
      end)
      assert results == [[:_0, 5]]
    end
  end

  # ============================================================
  # =/= in conde
  # ============================================================

  describe "=/= with conde" do
    test "=/= prunes branches" do
      # x is :a or :b, but x =/= :a
      results = run(5, fn q ->
        fresh x do
          Core.conj(
            diseq(x, :a),
            Core.conj(
              conde do
                [eq(x, :a), eq(q, :bad)]
                [eq(x, :b), eq(q, x)]
              end,
              eq(q, x)
            )
          )
        end
      end)
      assert results == [:b]
    end

    test "membero with disequality" do
      results = run(5, fn q ->
        Core.conj(
          diseq(q, 1),
          Relations.membero(q, [1, 2, 3])
        )
      end)
      assert results == [2, 3]
    end
  end

  # ============================================================
  # =/= with transitive bindings
  # ============================================================

  describe "transitive" do
    test "x =/= 5, y = x, then eq(y, 5) fails" do
      results = run(1, fn q ->
        fresh [x, y] do
          Core.conj(
            diseq(x, 5),
            Core.conj(
              eq(y, x),
              Core.conj(eq(y, 5), eq(q, :fail))
            )
          )
        end
      end)
      assert results == []
    end

    test "x =/= y, then unify x and y fails" do
      results = run(1, fn q ->
        fresh [x, y] do
          Core.conj(
            diseq(x, y),
            Core.conj(eq(x, y), eq(q, :fail))
          )
        end
      end)
      assert results == []
    end

    test "multiple diseqs all respected" do
      results = run(5, fn q ->
        fresh x do
          Core.conj(
            diseq(x, 1),
            Core.conj(
              diseq(x, 2),
              Core.conj(
                Relations.membero(x, [1, 2, 3, 4]),
                eq(q, x)
              )
            )
          )
        end
      end)
      assert results == [3, 4]
    end
  end

  # ============================================================
  # =/= with structures
  # ============================================================

  describe "structural disequality" do
    test "x =/= [1, 2]" do
      results = run(1, fn _q ->
        fresh x do
          Core.conj(
            diseq(x, [1, 2]),
            eq(x, [1, 2])
          )
        end
      end)
      assert results == []
    end

    test "x =/= [y], then unify x with [y] fails" do
      results = run(1, fn q ->
        fresh [x, y] do
          Core.conj(
            diseq(x, [y]),
            Core.conj(eq(x, [y]), eq(q, :fail))
          )
        end
      end)
      assert results == []
    end
  end
end
