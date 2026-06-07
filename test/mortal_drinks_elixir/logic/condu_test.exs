defmodule MortalDrinksElixir.Logic.ConduTest do
  use ExUnit.Case, async: false

  alias MortalDrinksElixir.Logic.{Core, MiniKanren, Relations}
  import MiniKanren

  describe "once" do
    test "once/1 takes first solution only" do
      results = run(5, fn q ->
        Core.once(
          conde do
            [eq(q, 1)]
            [eq(q, 2)]
            [eq(q, 3)]
          end
        )
      end)
      assert results == [1]
    end

    test "once on failure is empty" do
      results = run(1, fn _ ->
        Core.once(fn _ -> Core.mzero() end)
      end)
      assert results == []
    end
  end

  describe "ifte" do
    test "ifte(g, th, el): g succeeds → commits to th" do
      results = run(1, fn q ->
        Core.ifte(
          eq(:a, :a),           # g: succeeds
          eq(q, :th),           # th: q = :th
          eq(q, :el)            # el: not reached
        )
      end)
      assert results == [:th]
    end

    test "ifte(g, th, el): g fails → runs el" do
      results = run(1, fn q ->
        Core.ifte(
          eq(:a, :b),           # g: fails
          eq(q, :th),           # th: not reached
          eq(q, :el)            # el: q = :el
        )
      end)
      assert results == [:el]
    end
  end

  describe "condu" do
    test "condu commits on first guard success" do
      results = run(5, fn q ->
        condu do
          [eq(:a, :a), eq(q, :first)]    # guard passes → commit
          [eq(:a, :a), eq(q, :second)]   # never tried
        end
      end)
      assert results == [:first]
    end

    test "condu falls through failed guard" do
      results = run(5, fn q ->
        condu do
          [eq(:a, :b), eq(q, :first)]    # guard fails
          [eq(:x, :x), eq(q, :second)]   # guard passes → commit
          [eq(:x, :x), eq(q, :third)]    # never tried
        end
      end)
      assert results == [:second]
    end

    test "condu with fresh vars in guard" do
      results = run(5, fn q ->
        fresh x do
          condu do
            [eq(x, 1), eq(q, :one)]
            [eq(x, 2), eq(q, :two)]
          end
        end
      end)
      assert results == [:one]
    end

    test "condu vs conde: condu commits, conde explores all" do
      # conde would give both :a and :b
      conde_results = run(5, fn q ->
        conde do
          [eq(:x, :x), eq(q, :a)]
          [eq(:x, :x), eq(q, :b)]
        end
      end)
      assert Enum.sort(conde_results) == [:a, :b]

      # condu commits to first success
      condu_results = run(5, fn q ->
        condu do
          [eq(:x, :x), eq(q, :a)]
          [eq(:x, :x), eq(q, :b)]
        end
      end)
      assert condu_results == [:a]
    end
  end
end
