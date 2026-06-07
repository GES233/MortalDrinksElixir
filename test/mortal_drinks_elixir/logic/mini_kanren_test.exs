defmodule MortalDrinksElixir.Logic.MiniKanrenTest do
  use ExUnit.Case, async: true

  alias MortalDrinksElixir.Logic.Core
  import MortalDrinksElixir.Logic.MiniKanren

  # ============================================================
  # fresh
  # ============================================================

  describe "fresh" do
    test "single var" do
      results =
        run(1, fn q ->
          fresh x do
            Core.conj(eq(x, 42), eq(q, x))
          end
        end)

      assert results == [42]
    end

    test "multiple vars" do
      results =
        run(1, fn q ->
          fresh [a, b] do
            Core.conj(eq(a, 1), Core.conj(eq(b, 2), eq(q, [a, b])))
          end
        end)

      assert results == [[1, 2]]
    end

    test "three vars" do
      results =
        run(1, fn q ->
          fresh [a, b, c] do
            Core.conj(
              eq(a, :x),
              Core.conj(eq(b, :y), Core.conj(eq(c, :z), eq(q, [a, b, c])))
            )
          end
        end)

      assert results == [[:x, :y, :z]]
    end
  end

  # ============================================================
  # conde
  # ============================================================

  describe "conde" do
    test "two clauses, one succeeds" do
      results =
        run(5, fn q ->
          conde do
            [eq(q, :a), eq(:x, :x)]
            [eq(q, :b), eq(:x, :y)]
          end
        end)

      assert results == [:a]
    end

    test "both clauses succeed" do
      results =
        run(10, fn q ->
          conde do
            [eq(q, :a)]
            [eq(q, :b)]
          end
        end)

      assert Enum.sort(results) == [:a, :b]
    end

    test "three clauses" do
      results =
        run(10, fn q ->
          conde do
            [eq(q, 1)]
            [eq(q, 2)]
            [eq(q, 3)]
          end
        end)

      assert Enum.sort(results) == [1, 2, 3]
    end

    test "multi-goal clauses" do
      results =
        run(5, fn q ->
          fresh [x, y] do
            conde do
              [eq(x, :a), eq(y, 1), eq(q, {x, y})]
              [eq(x, :b), eq(y, 2), eq(q, {x, y})]
            end
          end
        end)

      assert Enum.sort(results) == [{:a, 1}, {:b, 2}]
    end

    test "conde with single clause behaves like conj" do
      results =
        run(1, fn q ->
          conde do
            [eq(q, :hello), eq(:a, :a)]
          end
        end)

      assert results == [:hello]
    end

    test "all clauses fail" do
      results =
        run(5, fn _ ->
          conde do
            [eq(:a, :b)]
            [eq(:c, :d)]
          end
        end)

      assert results == []
    end
  end

  # ============================================================
  # project
  # ============================================================

  describe "project" do
    test "extracts bound value for Elixir computation" do
      results =
        run(1, fn q ->
          fresh x do
            Core.conj(
              eq(x, 5),
              project [x] do
                eq(q, x + 1)
              end
            )
          end
        end)

      assert results == [6]
    end

    test "project returning nil fails the goal" do
      results =
        run(1, fn q ->
          project [q] do
            nil
          end
        end)

      assert results == []
    end

    test "project returning false fails the goal" do
      results =
        run(1, fn q ->
          project [q] do
            false
          end
        end)

      assert results == []
    end
  end

  test "diseq violated by later eq fails" do
    results =
      run(1, fn q ->
        fresh x do
          Core.conj(diseq(x, 1), Core.conj(eq(x, 1), eq(q, x)))
        end
      end)

    # 应该失败
    assert results == []
  end
end
