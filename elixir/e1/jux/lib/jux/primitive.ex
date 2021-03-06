defmodule Jux.Primitive do
  import Kernel, except: [to_string: 1, and: 2, or: 2]
  require Bitwise
  @moduledoc """
  Defines the native primitive function implementation known to this Elixir implementation.

  These are the 'building blocks' used in all programs.
  Anything not in here is tried to be converted to primitive function calls by use of the standard-library fallback rewrite rules.
  """

  # Primitive Stack Manipulation

  def dup([x | xs], kd) do
    {[x, x | xs], kd}
  end
  def dup(_, _), do: raise "Called `dup` without a value to duplicate on the stack."

  def swap([x, y | xs], kd) do
    {[y, x | xs], kd}
  end
  def swap(_, _), do: raise "Called `swap` without two values to swap on the stack."

  def pop([_x | xs], kd) do
    {xs, kd}
  end
  def pop(_, _), do: raise "Called `pop` while the stack is empty."

  # Combinators

  def dip([{quot, _t}, x | xs], known_definitions) when is_list(quot) do
    {new_stack, kd2} = Jux.Evaluator.evaluate_on(quot, xs, known_definitions)
    {[x | new_stack], kd2}
  end
  def dip( xs = [_, _ | _], _) do
    #IO.puts(Jux.stack_to_string(xs))
    raise "Called `dip` without a quotation"
  end
  def dip([_], _), do: raise "Called `dip` without enough elements on the stack"

  # Why does Joy call this thing infra?
  def infra([{quot, _t}, {list, _lt} | xs], known_definitions) when Kernel.and(is_list(quot), is_list(list)) do
    {result_stack, _} = Jux.Evaluator.evaluate_on(quot, list, known_definitions)
    {[{result_stack, "Quotation"} | xs], known_definitions}
  end

  # Conditionals

  # TODO: Tail-recursive
  def ifte([{else_quot, _}, {then_quot, _}, {condition_quot, _} | stack], known_definitions) when Kernel.and(is_list(else_quot), Kernel.and(is_list(then_quot), is_list(condition_quot))) do
    {stack2, kd2} = Jux.Evaluator.evaluate_on(condition_quot, stack, known_definitions)
    #IO.inspect(condition_check_stack)
    #IO.inspect(match?([false | _], condition_check_stack))
    case stack2 do
      [{false, "Boolean"} | stack2_rest] ->
        Jux.Evaluator.evaluate_on(else_quot, stack2_rest, kd2)
      [_ | stack2_rest] ->
        Jux.Evaluator.evaluate_on(then_quot, stack2_rest, kd2)
    end
  end

  # Arithmetic

  def add([{b, _t}, {a, t} | xs], kd) do
    {[{a + b, t} | xs], kd}
  end
  def add(_, _), do: raise "Called `add` with non-numeric parameters."
  # `sub` is only necessary if we are _not_ using two's complement. 
  # Otherwise, we can emulate it using y + (bnot(x)+1)

  # def sub([{b, _t}, {a, t} | xs], _) do
  #   #IO.inspect(a)
  #   #IO.inspect(b)
  #   [{a - b, t} | xs]
  # end
  # def sub(_, _), do: raise "Called `sub` with non-numeric parameters."

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

  def nand([{false, "Boolean"}, _     | xs], kd), do: {[{true, "Boolean"}  | xs], kd}
  def nand([_    , {false, "Boolean"} | xs], kd), do: {[{true, "Boolean"}  | xs], kd}
  def nand([_    , _     | xs], kd), do: {[{false, "Boolean"} | xs], kd}
  def nand(_, kd), do: raise "Called `nand` without two values to compare."

  # Bitwise

  # def bnot([{x, t} | xs], _), do: [{Bitwise.bnot(x), t} | xs]
  # def bor([{b, t}, {a, t} | xs], _), do: [{Bitwise.bor(a, b), t} | xs]
  # def band([{b, t}, {a, t} | xs], _), do: [Bitwise.band(a, b) | xs]

  def bnand([{b, t}, {a, t} | xs], kd), do: {[{Bitwise.bnot(Bitwise.band(a, b)), t} | xs], kd}

  # Comparisons

  def compare([{b, bt}, {a, at} | xs], kd) do
    #IO.inspect(b)
    #IO.inspect(a)
    {
      [{do_compare(b, a), "Integer"}, {b, bt}, {a, at} | xs],
      kd
    }
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
  defp do_compare([{b, _}|bs], [{a, _}|as]) do
    case do_compare(b, a) do
      0 ->
        do_compare(bs, as)
      result ->
        result
    end
  end

  def eq?([{b, bt}, {a, at} | xs], kd) do
    {
      [{do_compare(b, a) == 0, "Boolean"} , {b, bt}, {a, at} | xs],
      kd
    }
  end

  # Quotation operations

  def cons([x, {quot, t} | xs], kd) when is_list(quot) do
    {[{[x | quot], t} | xs], kd}
  end
  def cons(_, _), do: raise "Called `cons` without a quotation to construct with."

  def uncons([{[x | quot], t} | xs], kd) when is_list(quot) do
    {[x, {quot, t} | xs], kd}
  end

  def uncons([{[], _} | _xs], _) do
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

  # def to_string([x | xs], _) do
  #   [{do_to_string(x) |> Jux.elixir_charlist_to_jux_string, "String"} | xs]
  # end

  # def do_to_string({elem, "String"}) do
  #   elem
  # end

  # def do_to_string({list, _type}) when is_list(list) do
  #   content_str = 
  #     list
  #     |> Enum.map(fn elem -> 
  #       elem_str = do_to_string(elem)
  #       elem_str 
  #     end)
  #     |> Enum.reverse
  #     |> Enum.join(" ")
  #   "[#{content_str}]"
  #   |> String.to_charlist
  # end

  # def do_to_string({elem, _type}) do
  #   elem
  #   |> Kernel.to_charlist
  #   #|> Jux.elixir_charlist_to_jux_string
  # end

  def identifier_to_string([{elem = %_identifier{name: _name}, t} | xs], kd) do
    identifier_str = 
      elem
      |> Kernel.to_charlist
      |> Jux.elixir_charlist_to_jux_string
    {[{identifier_str, "String"}, xs], kd}
  end

  def string_to_identifier([{x, "String"} | xs], kd) when is_list(x) do
    x_str = Jux.jux_string_to_elixir_charlist(x) |> Kernel.to_string
    if Jux.Parser.valid_identifier?(x_str) do
      {[Jux.Identifier.new(x_str) | xs], kd}
    else
      raise "`#{x}` is not a valid Jux identifier!"
    end
  end

  def callable?([{x = %Jux.Identifier{name: name}, t} | xs], known_definitions) do
    result = known_definitions[name] != nil
    {[{result, "Boolean"} | xs], known_definitions}
  end

  # def string_concat([{b, "String"}, {a, "String"} | xs], _) do
  #   [(a <> b) | xs]
  # end

  # Basic Output

  def print([{x, "String"} | xs], kd) do
    x
    |> Jux.jux_string_to_elixir_charlist
    |> List.to_string
    |> Macro.unescape_string
    |> IO.write

    {xs, kd}
  end

  # Prevention of malformedness
  def crash([{x, "String"} | xs], _) when is_list(x) do
    raise "The Jux Program crashed with: " <> x
  end

  def type(stack = [{x, type} | xs], kd) do
    {
      [{Jux.Identifier.new(type), "Type"} | stack],
      kd
    }
  end

  def cast_to([{%Jux.Identifier{name: name}, _}, {x, _} | xs], kd) do
    {
      [{x, name} | xs], 
      kd
    }
  end

  # Not a required function, but a nice-to-have during development.
  def inspect_stack(xs, kd) do
    IO.puts("inspected stack: " <> Jux.stack_to_string(xs, false))
    {xs, kd}
  end
end
