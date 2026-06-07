defmodule MortalDrinksElixir.Logic.RelationsTest do
  use ExUnit.Case, async: false

  alias MortalDrinksElixir.Logic.Core
  alias MortalDrinksElixir.Logic.Relations

  # ============================================================
  # nullo
  # ============================================================

  describe "nullo/1" do
    test "succeeds for empty list" do
      results = Core.run(1, fn q -> Relations.nullo([]) end)
      assert length(results) == 1
    end

    test "fails for non-empty list" do
      results = Core.run(1, fn _ -> Relations.nullo([1]) end)
      assert results == []
    end

    test "binds variable to []" do
      results = Core.run(1, fn q -> Relations.nullo(q) end)
      assert results == [[]]
    end
  end

  # ============================================================
  # pairo
  # ============================================================

  describe "pairo/1" do
    test "succeeds for non-empty list" do
      results = Core.run(1, fn _ -> Relations.pairo([1, 2]) end)
      assert length(results) == 1
    end

    test "fails for empty list" do
      results = Core.run(1, fn _ -> Relations.pairo([]) end)
      assert results == []
    end

    test "variable becomes a pair" do
      results = Core.run(1, fn q -> Relations.pairo(q) end)
      assert [[_a | _b]] = results  # q = [a | d] → reified as [:_0 | :_1] (improper list)
    end
  end

  # ============================================================
  # caro / cdro
  # ============================================================

  describe "caro/2" do
    test "extracts head" do
      results = Core.run(1, fn q -> Relations.caro([1, 2, 3], q) end)
      assert results == [1]
    end

    test "fails on empty list" do
      results = Core.run(1, fn q -> Relations.caro([], q) end)
      assert results == []
    end

    test "constructs list from head" do
      results = Core.run(1, fn q -> Relations.caro(q, :a) end)
      assert [[:a | _d]] = results
    end
  end

  describe "cdro/2" do
    test "extracts tail" do
      results = Core.run(1, fn q -> Relations.cdro([1, 2, 3], q) end)
      assert results == [[2, 3]]
    end

    test "fails on empty list" do
      results = Core.run(1, fn q -> Relations.cdro([], q) end)
      assert results == []
    end

    test "constructs list from tail" do
      results = Core.run(1, fn q -> Relations.cdro(q, [2, 3]) end)
      assert [[_a, 2, 3]] = results
    end
  end

  # ============================================================
  # conso
  # ============================================================

  describe "conso/3" do
    test "construct list from head and tail" do
      results = Core.run(1, fn q -> Relations.conso(1, [2, 3], q) end)
      assert results == [[1, 2, 3]]
    end

    test "deconstruct list into head and tail" do
      results =
        Core.run(1, fn q ->
          Core.call_fresh(fn a ->
            Core.call_fresh(fn d ->
              Core.conj(
                Relations.conso(a, d, [1, 2, 3]),
                Core.eq(q, [a, d])
              )
            end)
          end)
        end)

      assert results == [[1, [2, 3]]]
    end

    test "head + variable tail = known list" do
      results = Core.run(1, fn q -> Relations.conso(:a, q, [:a, :b, :c]) end)
      assert results == [[:b, :c]]
    end
  end

  # ============================================================
  # appendo
  # ============================================================

  describe "appendo/3" do
    test "[1,2] ++ [3] = [1,2,3]" do
      results = Core.run(1, fn q -> Relations.appendo([1, 2], [3], q) end)
      assert results == [[1, 2, 3]]
    end

    test "[] ++ x = x" do
      results = Core.run(1, fn q -> Relations.appendo([], [1, 2], q) end)
      assert results == [[1, 2]]
    end

    test "x ++ [] = x" do
      results = Core.run(1, fn q -> Relations.appendo([1, 2], [], q) end)
      assert results == [[1, 2]]
    end

    test "find what appends with [2,3] to get [1,2,3]" do
      results = Core.run(1, fn q -> Relations.appendo(q, [2, 3], [1, 2, 3]) end)
      assert results == [[1]]
    end

    test "find what [1] appends with to get [1,2,3]" do
      results = Core.run(1, fn q -> Relations.appendo([1], q, [1, 2, 3]) end)
      assert results == [[2, 3]]
    end

    test "find all pairs that append to [1,2]" do
      results =
        Core.run(3, fn q ->
          Core.call_fresh(fn a ->
            Core.call_fresh(fn b ->
              Core.conj(
                Relations.appendo(a, b, [1, 2]),
                Core.eq(q, [a, b])
              )
            end)
          end)
        end)

      # Should be: [[], [1,2]], [[1], [2]], [[1,2], []]
      assert length(results) == 3
      assert [[], [1, 2]] in results
      assert [[1], [2]] in results
      assert [[1, 2], []] in results
    end
  end

  # ============================================================
  # membero
  # ============================================================

  describe "membero/2" do
    test "member of list" do
      results = Core.run(1, fn _ -> Relations.membero(2, [1, 2, 3]) end)
      assert length(results) == 1
    end

    test "not a member" do
      results = Core.run(1, fn _ -> Relations.membero(9, [1, 2, 3]) end)
      assert results == []
    end

    test "find members" do
      results = Core.run(3, fn q -> Relations.membero(q, [1, 2, 3]) end)
      assert Enum.sort(results) == [1, 2, 3]
    end

    test "membero of empty list fails" do
      results = Core.run(1, fn _ -> Relations.membero(1, []) end)
      assert results == []
    end
  end

  # ============================================================
  # listo
  # ============================================================

  describe "listo/1" do
    test "empty list is proper" do
      results = Core.run(1, fn _ -> Relations.listo([]) end)
      assert length(results) == 1
    end

    test "non-empty list is proper" do
      results = Core.run(1, fn _ -> Relations.listo([1, 2, 3]) end)
      assert length(results) == 1
    end

    test "variable becomes proper list" do
      results = Core.run(3, fn q -> Relations.listo(q) end)
      assert [] in results
      # The others are lists of unbound vars
    end
  end
end
