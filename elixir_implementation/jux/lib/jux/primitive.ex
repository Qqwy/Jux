defmodule Jux.Primitive do
  import Kernel, except: [to_string: 1, and: 2, or: 2]
  require Bitwise
  @moduledoc """
  Defines the native primitive function implementation known to this Elixir implementation.

  These are the 'building blocks' used in all programs.
  Anything not in here is tried to be converted to primitive function calls by use of the standard-library fallback rewrite rules.
  """

  # Primitive Stack Manipulation

  def dup([x | xs], _) do
    [x, x | xs]
  end
  def dup(_, _), do: raise "Called `dup` without a value to duplicate on the stack."

  def swap([x, y | xs], _) do
    [y, x | xs]
  end
  def swap(_, _), do: raise "Called `swap` without two values to swap on the stack."

  def pop([_x | xs], _) do
    xs
  end
  def pop(_, _), do: raise "Called `pop` while the stack is empty."

  # Combinators

  def dip([quot, x | xs], known_definitions) when is_list(quot) do
    {new_stack, _} = Jux.Evaluator.evaluate_on(quot, xs, known_definitions)
    [x | new_stack]
  end
  def dip( xs = [_, _ | _], _) do
    IO.puts(Jux.stack_to_string(xs))
    raise "Called `dip` without a quotation"
  end
  def dip([_], _), do: raise "Called `dip` without enough elements on the stack"

  # Conditionals

  def ifte([else_quot, then_quot, condition_quot | xs], known_definitions) when Kernel.and(is_list(else_quot), Kernel.and(is_list(then_quot), is_list(condition_quot))) do
    {condition_check_stack, _} = Jux.Evaluator.evaluate_on(condition_quot, xs, known_definitions)
    #IO.inspect(condition_check_stack)
    #IO.inspect(match?([false | _], condition_check_stack))
    if match?([false | _], condition_check_stack) do
      {new_stack, _} = Jux.Evaluator.evaluate_on(else_quot, xs, known_definitions)
    else
      {new_stack, _} = Jux.Evaluator.evaluate_on(then_quot, xs, known_definitions)
    end
    new_stack
  end

  # Arithmetic

  def add([b, a | xs], _) do
    [a + b | xs]
  end
  def add(_, _), do: raise "Called `add` with non-numeric parameters."

  def sub([b, a | xs], _) do
    #IO.inspect(a)
    #IO.inspect(b)
    [a - b | xs]
  end
  def sub(_, _), do: raise "Called `sub` with non-numeric parameters."

  # def mul([b, a | xs], _) do
  #   [a * b | xs]
  # end
  # def mul(_, _), do: raise "Called `mul` with non-numeric parameters."

  # Boolean

  # def unquote(true)(xs, _) do
  #   [true | xs]
  # end

  # def unquote(false)(xs, _) do
  #   [false | xs]
  # end

  # def unquote(:not)(xs, _)
  # def unquote(:not)([false | xs], _), do: [true | xs]
  # def unquote(:not)([_ | xs], _), do: [false | xs]

  # def unquote(:or)([false, false | xs], _), do: [false | xs]
  # def unquote(:or)([_    , _     | xs], _), do: [true | xs]
  # def unquote(:or)(_, _), do: raise "Called `or` without two values to compare."

  # def unquote(:and)([false, _     | xs], _), do: [false | xs]
  # def unquote(:and)([_    , false | xs], _), do: [false | xs]
  # def unquote(:and)([_    , _     | xs], _), do: [true | xs]
  # def unquote(:and)(_, _), do: raise "Called `and` without two values to compare."

  def nand([false, _     | xs], _), do: [true  | xs]
  def nand([_    , false | xs], _), do: [true  | xs]
  def nand([_    , _     | xs], _), do: [false | xs]
  def nand(_, _), do: raise "Called `nand` without two values to compare."

  # Bitwise

  def bnot([x | xs], _), do: [Bitwise.bnot(x) | xs]
  def bor([b, a | xs], _), do: [Bitwise.bor(a, b) | xs]
  def band([b, a | xs], _), do: [Bitwise.band(a, b) | xs]

  # Comparisons

  def compare([b, a | xs], _) do
    [do_compare(b, a) | xs]
  end

  # element always eq to itself
  defp do_compare(x, x), do: 0

  # Number vs Number
  defp do_compare(b, a) when Kernel.and(is_number(a), Kernel.and(is_number(b), a < b)), do: -1
  defp do_compare(b, a) when Kernel.and(is_number(a), Kernel.and(is_number(b), a > b)), do:  1
  defp do_compare(b, a) when Kernel.and(is_number(a), is_number(b))                   , do:  0

  # Number < (Boolean, Identifier, String, Quotation)
  defp do_compare(b, a) when Kernel.and(is_number(a), Kernel.not(is_number(b))), do: -1
  defp do_compare(b, a) when Kernel.and(is_number(b), Kernel.not(is_number(a))), do:  1

  # Boolean vs Boolean
  defp do_compare(false, true), do: -1
  defp do_compare(true, false), do:  1

  # Boolean < (Identifier, String, Quotation)
  defp do_compare(b, a) when Kernel.and(is_boolean(a), Kernel.not(is_boolean(b))), do: -1
  defp do_compare(b, a) when Kernel.and(is_boolean(b), Kernel.not(is_boolean(a))), do:  1

  # Identifier vs Identifier
  defp do_compare(%Jux.Identifier{name: name_b}, %Jux.Identifier{name: name_a}) when name_a < name_b, do: -1
  defp do_compare(%Jux.Identifier{name: name_b}, %Jux.Identifier{name: name_a}) when name_b < name_a, do:  1
  defp do_compare(%Jux.Identifier{}            , %Jux.Identifier{})                                 , do:  0

  # Identifier < (String, Quotation)
  defp do_compare(_                 , %Jux.Identifier{}), do: -1
  defp do_compare(%Jux.Identifier{},_                  ), do:  1

  # String vs String
  defp do_compare(b, a) when Kernel.and(is_binary(a), Kernel.and(is_binary(b), a < b)), do: -1
  defp do_compare(b, a) when Kernel.and(is_binary(a), Kernel.and(is_binary(b), a > b)), do:  1
  defp do_compare(b, a) when Kernel.and(is_binary(a), is_binary(b))                   , do:  0

  # String < Quotation
  defp do_compare(b, a) when Kernel.and(is_binary(a), is_list(b)), do: -1
  defp do_compare(b, a) when Kernel.and(is_binary(b), is_list(a)), do:  1

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

  def eq?([b, a | xs], _) do
    [do_compare(b, a) == 0 | xs]
  end

  # Quotation operations

  def cons([x, quot | xs], _) when is_list(quot) do
    [[x | quot] | xs]
  end
  def cons(_, _), do: raise "Called `cons` without a quotation to construct with."

  def uncons([[x | quot] | xs], _) when is_list(quot) do
    [x, quot | xs]
  end

  def uncons([[] | _xs], _) do
    raise "Called `uncons` with an empty quotation to deconstruct."  
  end
  def uncons(_, _), do: raise "Called `uncons` without a quotation to deconstruct."

  # TODO
 #  def foldl([quot, acc, list | xs], _) when Kernel.and(is_list(quot), is_list(list)) do
 #    stack = [acc | xs]
 #    Enum.reduce(list, stack, fn elem, stack -> 
 #      {new_stack, _} = Jux.Evaluator.evaluate_on(quot, [elem | stack])
 #      new_stack
 #    end)
 #  end
 #  def foldl(xs, _) do
 #    IO.puts(Jux.stack_to_string(xs))
 #    raise "Called `foldl` with wrong parameters."
 # end
  # String operations

  def to_string([x | xs], _) do
    [Kernel.to_string(x) | xs]
  end

  def to_identifier([x | xs], _) when is_binary(x) do
    if Jux.Parser.valid_identifier?(x) do
      [Jux.Identifier.new(x) | xs]
    else
      raise "`#{x}` is not a valid Jux identifier!"
    end
  end

  def callable?([x = %Jux.Identifier{name: name} | xs], known_definitions) do
    result = known_definitions[name] != nil
    [result | xs]
  end

  def string_concat([b, a | xs], _) do
    [(a <> b) | xs]
  end

  # Basic Output

  def print([x | xs], _) do
    IO.write(x)
    xs
  end

  # Prevention of malformedness
  def crash([x | xs], _) when is_binary(x) do
    raise "The Jux Program crashed with: " <> x
  end

  # Not a required function, but a nice-to-have during development.
  def inspect_stack(xs, _) do
    IO.puts("inspected stack: " <> Jux.stack_to_string(xs))
    xs
  end

end
