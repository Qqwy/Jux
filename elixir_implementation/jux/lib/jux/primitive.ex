defmodule Jux.Primitive do
  import Kernel, except: [to_string: 1]
  require Bitwise
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

  def pop([_x | xs]) do
    xs
  end
  def pop(_), do: raise "Called `pop` while the stack is empty."

  # Combinators

  def dip([quot, x | xs]) when is_list(quot) do
    new_stack = Jux.Evaluator.evaluate_on(quot, xs)
    [x | new_stack]
  end
  def dip( xs = [_, _ | _]) do
    IO.puts(Jux.stack_to_string(xs))
    raise "Called `dip` without a quotation"
  end
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
  def sub(_), do: raise "Called `sub` with non-numeric parameters."

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
  def unquote(:or)(_), do: raise "Called `or` without two values to compare."

  def unquote(:and)([false, _     | xs]), do: [false | xs]
  def unquote(:and)([_    , false | xs]), do: [false | xs]
  def unquote(:and)([_    , _     | xs]), do: [true | xs]
  def unquote(:and)(_), do: raise "Called `and` without two values to compare."

  # Bitwise

  def bnot([x | xs]), do: [Bitwise.bnot(x) | xs]
  def bor([b, a | xs]), do: [Bitwise.bor(a, b) | xs]
  def band([b, a | xs]), do: [Bitwise.band(a, b) | xs]

  # Comparisons

  def compare([b, a | xs]) do
    [do_compare(b, a) | xs]
  end

  # element always eq to itself
  defp do_compare(x, x), do: 0

  # Number vs Number
  defp do_compare(b, a) when is_number(a) and is_number(b) and a < b, do: -1
  defp do_compare(b, a) when is_number(a) and is_number(b) and a > b, do:  1
  defp do_compare(b, a) when is_number(a) and is_number(b)          , do:  0

  # Number < (Boolean, Identifier, String, Quotation)
  defp do_compare(b, a) when is_number(a) and Kernel.not(is_number(b)), do: -1
  defp do_compare(b, a) when is_number(b) and Kernel.not(is_number(a)), do:  1

  # Boolean vs Boolean
  defp do_compare(false, true), do: -1
  defp do_compare(true, false), do:  1

  # Boolean < (Identifier, String, Quotation)
  defp do_compare(b, a) when is_boolean(a) and Kernel.not(is_boolean(b)), do: -1
  defp do_compare(b, a) when is_boolean(b) and Kernel.not(is_boolean(a)), do:  1

  # Identifier vs Identifier
  defp do_compare(%Jux.Identifier{name: name_b}, %Jux.Identifier{name: name_a}) when name_a < name_b, do: -1
  defp do_compare(%Jux.Identifier{name: name_b}, %Jux.Identifier{name: name_a}) when name_b < name_a, do:  1
  defp do_compare(%Jux.Identifier{}            , %Jux.Identifier{})                                 , do:  0

  # Identifier < (String, Quotation)
  defp do_compare(_                 , %Jux.Identifier{}), do: -1
  defp do_compare(%Jux.Identifier{},_                  ), do:  1

  # String vs String
  defp do_compare(b, a) when is_binary(a) and is_binary(b) and a < b, do: -1
  defp do_compare(b, a) when is_binary(a) and is_binary(b) and a > b, do:  1
  defp do_compare(b, a) when is_binary(a) and is_binary(b)          , do:  0

  # String < Quotation
  defp do_compare(b, a) when is_binary(a) and is_list(b), do: -1
  defp do_compare(b, a) when is_binary(b) and is_list(a), do:  1

  # Quotation vs Quotation
  defp do_compare([], _as), do: 1
  defp do_compare(_bs, []), do: -1
  defp do_compare([b|bs], [a|as]) do
    case do_compare(b, a) do
      0 ->
        do_compare(bs, as)
      result ->
        result
    end
  end

  def eq?([b, a | xs]) do
    [do_compare(b, a) == 0 | xs]
  end

  # Quotation operations

  def cons([x, quot | xs]) when is_list(quot) do
    [[x | quot] | xs]
  end
  def cons(_), do: raise "Called `cons` without a quotation to construct with."

  def uncons([[x | quot] | xs]) when is_list(quot) do
    [x, quot | xs]
  end

  def uncons([[] | _xs]) do
    raise "Called `uncons` with an empty quotation to deconstruct."  
  end
  def uncons(_), do: raise "Called `uncons` without a quotation to deconstruct."

  # TODO
  def foldl([quot, acc, list | xs]) when is_list(quot) and is_list(list) do
    stack = [acc | xs]
    Enum.reduce(list, stack, fn elem, stack -> 
      Jux.Evaluator.evaluate_on(quot, [elem | stack])
    end)
  end
  def foldl(_), do: raise "Called `reduce` with wrong parameters."

  # String operations

  def to_string([x | xs]) do
    [Kernel.to_string(x) | xs]
  end

  def string_concat([b, a | xs]) do
    [(a <> b) | xs]
  end

  # Basic Output

  def print([x | xs]) do
    IO.write(x)
    xs
  end

end
