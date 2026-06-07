defmodule MortalDrinksElixir.Logic.TypeoTest do
  use ExUnit.Case, async: false

  alias MortalDrinksElixir.Logic.{Core, MiniKanren, Relations}
  import MiniKanren

  describe "symbolo" do
    test "atom passes" do
      results = run(1, fn _ -> symbolo(:hello) end)
      assert length(results) == 1
    end

    test "number fails" do
      results = run(1, fn _ -> symbolo(42) end)
      assert results == []
    end

    test "var + eq(:atom) succeeds" do
      results = run(1, fn _ ->
        fresh x do
          Core.conj(symbolo(x), eq(x, :ok))
        end
      end)
      assert length(results) == 1
    end

    test "var + eq(42) fails" do
      results = run(1, fn _ ->
        fresh x do
          Core.conj(symbolo(x), eq(x, 42))
        end
      end)
      assert results == []
    end
  end

  describe "numbero" do
    test "number passes" do
      results = run(1, fn _ -> numbero(42) end)
      assert length(results) == 1
    end

    test "int and float both pass" do
      results = run(1, fn _ -> numbero(3.14) end)
      assert length(results) == 1
    end

    test "atom fails" do
      results = run(1, fn _ -> numbero(:nope) end)
      assert results == []
    end

    test "var + eq(42) succeeds" do
      results = run(1, fn _ ->
        fresh x do
          Core.conj(numbero(x), eq(x, 42))
        end
      end)
      assert length(results) == 1
    end

    test "var + eq(:atom) fails" do
      results = run(1, fn _ ->
        fresh x do
          Core.conj(numbero(x), eq(x, :nope))
        end
      end)
      assert results == []
    end
  end

  describe "type constraints with membero" do
    test "numbero filters list" do
      results = run(5, fn q ->
        Core.conj(numbero(q), Relations.membero(q, [:a, 1, :b, 2, :c]))
      end)
      assert results == [1, 2]
    end

    test "symbolo filters list" do
      results = run(5, fn q ->
        Core.conj(symbolo(q), Relations.membero(q, [:a, 1, :b, 2]))
      end)
      assert Enum.sort(results) == [:a, :b]
    end
  end

  describe "run multi-var" do
    test "two vars" do
      results = run(1, 2, fn [q, x] ->
        Core.conj(eq(x, 10), eq(q, x))
      end)
      assert results == [{10, 10}]
    end

    test "three vars with disj" do
      results = run(5, 3, fn [a, b, c] ->
        Core.conj(
          Core.conj(eq(a, 1), eq(b, 2)),
          Core.disj(eq(c, :x), eq(c, :y))
        )
      end)
      assert [{1, 2, :x}, {1, 2, :y}] = Enum.sort(results)
    end
  end
end
