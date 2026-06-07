defmodule MortalDrinksElixir.Logic.AbsentoTest do
  use ExUnit.Case, async: false

  alias MortalDrinksElixir.Logic.{Core, MiniKanren, Relations}
  import MiniKanren

  # ============================================================
  # Immediate check
  # ============================================================

  describe "immediate" do
    test "absento(:a, :a) fails" do
      results = run(1, fn _ -> absento(:a, :a) end)
      assert results == []
    end

    test "absento(:a, :b) succeeds" do
      results = run(1, fn _ -> absento(:a, :b) end)
      assert length(results) == 1
    end

    test "absento(:a, [:a]) fails (nested)" do
      results = run(1, fn _ -> absento(:a, [:a]) end)
      assert results == []
    end

    test "absento(:a, [:b, :c]) succeeds" do
      results = run(1, fn _ -> absento(:a, [:b, :c]) end)
      assert length(results) == 1
    end

    test "absento(:a, [1, [:a, 2]]) fails (deep nested)" do
      results = run(1, fn _ -> absento(:a, [1, [:a, 2]]) end)
      assert results == []
    end

    test "absento(:a, {:ok, :a}) fails (tuple)" do
      results = run(1, fn _ -> absento(:a, {:ok, :a}) end)
      assert results == []
    end

    test "absento(:a, {:ok, :b}) succeeds (tuple)" do
      results = run(1, fn _ -> absento(:a, {:ok, :b}) end)
      assert length(results) == 1
    end
  end

  # ============================================================
  # Variable: deferred check
  # ============================================================

  describe "deferred via variable" do
    test "absento(:a, x), then eq(x, :a) fails" do
      results = run(1, fn _q ->
        fresh x do
          Core.conj(absento(:a, x), eq(x, :a))
        end
      end)
      assert results == []
    end

    test "absento(:a, x), then eq(x, :b) succeeds" do
      results = run(1, fn q ->
        fresh x do
          Core.conj(absento(:a, x), Core.conj(eq(x, :b), eq(q, x)))
        end
      end)
      assert results == [:b]
    end

    test "absento(:a, x), then eq(x, [:a]) fails" do
      results = run(1, fn _q ->
        fresh x do
          Core.conj(absento(:a, x), eq(x, [:a]))
        end
      end)
      assert results == []
    end

    test "absento(:a, x), then eq(x, [:b, :c]) succeeds" do
      results = run(1, fn q ->
        fresh x do
          Core.conj(absento(:a, x), Core.conj(eq(x, [:b, :c]), eq(q, x)))
        end
      end)
      assert results == [[:b, :c]]
    end

    test "absento(:a, [x, y]), eq(x, :a) fails" do
      results = run(1, fn _q ->
        fresh [x, y] do
          Core.conj(absento(:a, [x, y]), eq(x, :a))
        end
      end)
      assert results == []
    end

    test "absento(:a, [x, y]), eq(y, :a) fails" do
      results = run(1, fn _q ->
        fresh [x, y] do
          Core.conj(absento(:a, [x, y]), eq(y, :a))
        end
      end)
      assert results == []
    end
  end

  # ============================================================
  # With membero
  # ============================================================

  describe "with membero" do
    test "absento(:a, q), membero(q, [:a, :b, :c]) gives [:b, :c]" do
      results = run(5, fn q ->
        Core.conj(absento(:a, q), Relations.membero(q, [:a, :b, :c]))
      end)
      assert results == [:b, :c]
    end

    test "absento(:a, q), membero(q, [:a]) fails" do
      results = run(5, fn q ->
        Core.conj(absento(:a, q), Relations.membero(q, [:a]))
      end)
      assert results == []
    end
  end

  # ============================================================
  # With =/=
  # ============================================================

  describe "absento + =/=" do
    test "both constraints active" do
      results = run(5, fn q ->
        fresh x do
          Core.conj(
            absento(:a, x),
            Core.conj(
              diseq(x, :b),
              Core.conj(
                Relations.membero(x, [:a, :b, :c]),
                eq(q, x)
              )
            )
          )
        end
      end)
      assert results == [:c]
    end
  end

  # ============================================================
  # Transitive binding
  # ============================================================

  describe "transitive" do
    test "absento(:a, x), eq(x, y), eq(y, :a) fails" do
      results = run(1, fn _q ->
        fresh [x, y] do
          Core.conj(absento(:a, x), Core.conj(eq(x, y), eq(y, :a)))
        end
      end)
      assert results == []
    end
  end
end
