defmodule Jux.Primitives do
  def dup(state) do
    update_in(state.stack, fn
      [] -> raise "Error, empty stack"
      [x|xs] -> [x,x|xs]
    end)
  end

  def swap(state) do
    update_in(state.stack, fn
      [] -> raise "Error, empty stack"
      [x] -> raise "Error, one element stack"
      [x,y|rest] -> [y,x|rest]
    end)
  end

  def pop(state) do
    update_in(state.stack, fn
      [] -> raise "Error, empty stack"
      [x|rest] -> rest
    end)
  end

  def add(state) do
    update_in(state.stack, fn
      [] -> raise "Error, empty stack"
      [x] -> raise "Error, one element stack"
      [x,y|rest] -> [x + y|rest]
    end)
  end

  def bnand(state) do
    use Bitwise
    update_in(state.stack, fn
      [] -> raise "Error, empty stack"
      [x] -> raise "Error, one element stack"
      [x,y|rest] -> [bnot(x &&& y)|rest]
    end)
  end
end
