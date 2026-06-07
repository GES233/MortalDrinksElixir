defmodule MortalDrinksElixir.Logic.Utils do
  def succeed, do: fn s -> [s] end
  def fail, do: fn _s -> [] end
end
