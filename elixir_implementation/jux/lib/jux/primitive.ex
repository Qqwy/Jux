defmodule Jux.Primitive do
  @moduledoc """
  Defines the native primitive function implementation known to this Elixir implementation.

  These are the 'building blocks' used in all programs.
  Anything not in here is tried to be converted to primitive function calls by use of the standard-library fallback rewrite rules.
  """

  # Primitive Stack Manipulation

  def dup([x | xs]) do
    [x, x | xs]
  end
  def dup(_), do: raise "Called `dup` without a value to duplicate on the stack."

  def swap([x, y | xs]) do
    [y, x | xs]
  end
  def swap(_), do: raise "Called `swap` without two values to swap on the stack."

  def pop([x | xs]) do
    xs
  end
  def swap(_), do: raise "Called `pop` while the stack is empty."

  # Combinators

  def dip([quot, x | xs]) when is_list(quot) do
    new_stack = Jux.Evaluator.evaluate_on(quot, xs)
    [x | new_stack]
  end
  def dip([_, _ | _]), do: raise "Called `dip` without a quotation"
  def dip([_]), do: raise "Called `dip` without enough elements on the stack"

  # Conditionals

  def ifte([else_quot, then_quot, condition_quot | xs]) when is_list(else_quot) and is_list(then_quot) and is_list(condition_quot) do
    condition_check_stack = Jux.Evaluator.evaluate_on(condition_quot, xs)
    if match?([false | _], condition_check_stack) do
      Jux.Evaluator.evaluate_on(else_quot, xs)
    else
      Jux.Evaluator.evaluate_on(then_quot, xs)
    end
  end

  # Arithmetic

  def add([b, a | xs]) do
    [a + b | xs]
  end
  def add(_), do: raise "Called `add` with non-numeric parameters."

  def sub([b, a | xs]) do
    [a - b | xs]
  end
  def add(_), do: raise "Called `sub` with non-numeric parameters."

  # Boolean

  def unquote(true)(xs) do
    [true | xs]
  end

  def unquote(false)(xs) do
    [false | xs]
  end

  def not(xs)
  def not([false | xs]), do: [true | xs]
  def not([_ | xs]), do: [false | xs]

  def unquote(:or)([false, false | xs]), do: [false | xs]
  def unquote(:or)([_    , _     | xs]), do: [true | xs]
  def unquote(:or)(), do: raise "Called `or` without two values to compare."

  def unquote(:and)([false, _     | xs]), do: [false | xs]
  def unquote(:and)([_    , false | xs]), do: [false | xs]
  def unquote(:and)([_    , _     | xs]), do: [true | xs]
  def unquote(:and)(), do: raise "Called `and` without two values to compare."

  # Comparisons

  # element always eq to itself
  def compare([x, x | xs]), do: 0

  # Number < Boolean
  def compare([b, a | xs]) when is_number(a) and is_boolean(b), do: -1
  def compare([b, a | xs]) when is_number(b) and is_boolean(a), do:  1

  # Number < Identifier
  def compare([b = %Jux.Identifier{}, a                     | xs]) when is_number(a), do: -1
  def compare([b                    , a = %Jux.Identifier{} | xs]) when is_number(b), do:  1

  # Number < String
  def compare([b, a | xs]) when is_number(a) and is_binary(b), do: -1
  def compare([b, a | xs]) when is_number(b) and is_binary(a), do:  1

  # Number < Quotation
  def compare([b, a | xs]) when is_number(a) and is_list(b), do: -1
  def compare([b, a | xs]) when is_number(b) and is_list(a), do:  1


  # Boolean < Identifier
  def compare([b = %Jux.Identifier{}, a                     | xs]) when is_boolean(a), do: -1
  def compare([b                    , a = %Jux.Identifier{} | xs]) when is_boolean(b), do:  1

  # Boolean < String
  def compare([b, a | xs]) when is_boolean(a) and is_binary(b), do: -1
  def compare([b, a | xs]) when is_boolean(b) and is_binary(a), do:  1

  # Boolean < Quotation
  def compare([b, a | xs]) when is_boolean(a) and is_list(b), do: -1
  def compare([b, a | xs]) when is_boolean(b) and is_list(a), do:  1

  # Identifier < String
  def compare([b                    , a = %Jux.Identifier{} | xs]) when is_string(b), do: -1
  def compare([b = %Jux.Identifier{}, a                     | xs]) when is_string(a), do:  1

  # Identifier < Quotation
  def compare([b                    , a = %Jux.Identifier{} | xs]) when is_list(b), do: -1
  def compare([b = %Jux.Identifier{}, a                     | xs]) when is_list(a), do:  1

  # String < Quotation
  def compare([b, a | xs]) when is_string(a) and is_list(b), do: -1
  def compare([b, a | xs]) when is_string(b) and is_list(a), do:  1


  # Number vs Number
  def compare([b, a | xs]) when is_number(a) and is_number(b) and a < b, do: -1
  def compare([b, a | xs]) when is_number(a) and is_number(b) and a > b, do:  1
  def compare([b, a | xs]) when is_number(a) and is_number(b)          , do:  0

  # String vs String
  def compare([b, a | xs]) when is_binary(a) and is_binary(b) and a < b, do: -1
  def compare([b, a | xs]) when is_binary(a) and is_binary(b) and a > b, do:  1
  def compare([b, a | xs]) when is_binary(a) and is_binary(b)          , do:  0

  # Identifier vs Identifier
  def compare([b = %Jux.Identifier{name: name_b}, a = %Jux.Identifier{name: name_a} | xs]) when name_a < name_b, do: -1
  def compare([b = %Jux.Identifier{name: name_b}, a = %Jux.Identifier{name: name_a} | xs]) when name_a < name_b, do:  1
  def compare([b = %Jux.Identifier{name: name_b}, a = %Jux.Identifier{name: name_a} | xs])                     , do:  0



  # Quotation operations

  def cons([x, quot | xs]) when is_list(quot) do
    [[x | quot] | xs]
  end
  def cons(_), do: raise "Called `cons` without a quotation to construct with."

  def uncons([[x | quot] | xs]) when is_list(quot) do
    [x, quot | xs]
  end

  def uncons([[] | xs]) do
    raise "Called `uncons` with an empty quotation to deconstruct."  
  end
  def uncons(_), do: raise "Called `uncons` without a quotation to deconstruct."

  # TODO
  def reduce([quot, acc, list | xs]) when is_list(quot) and is_list(list) do
    stack = [acc | xs]
    Enum.reduce(list, stack, fn elem, stack -> 
      Jux.Evaluator.evaluate_on(quot, [elem, stack])
    end)
  end
  def reduce(_), do: raise "Called `reduce` with wrong parameters."

end
