defmodule Jux.Rewrite do
  defmacro rewrite(name, source) do
    quote bind_quoted: [name: name, source: source] do
      def unquote(name |> String.to_atom)(fun_stack) do
        rewritten_fun_queue = 
          unquote(quote do Jux.Parser.parse(unquote(source)) end)
          |> :lists.reverse
        rewritten_fun_queue ++ fun_stack
      end
    end
  end
end

defmodule Jux.Fallback do
  @moduledoc """
  This module contains all the fallback rewrite rules,
  that are used when a function does not have a primitive native implementation,
  to rewrite it to one or multiple functions that _are_ primitives.
  """
  import Jux.Rewrite

  rewrite "i", "dup dip pop"
  rewrite "inc", "1 add"
  rewrite "dec", "1 sub"
  rewrite "id", ""
  rewrite "b", "[i] dip i"
  rewrite "length", "0 [inc] reduce"
  rewrite "sum", "0 [add] reduce"
  #rewrite "product", "1 [mul] reduce"
  rewrite "append", "swap [cons] reduce"
  rewrite "map", "[] swap [cons] append reduce"
  rewrite "if", "[] ifelse"
  rewrite "unless", "[] swap ifelse"
  rewrite "dip2", "[i] dip"
  rewrite "dip3", "[dip2] dip"
  rewrite "swap2", "swap [swap] dip"

  rewrite "Z X Y primrec", "Z [[ pop 0 eq?] [pop pop X] [[dup 1 sub] dip dup i Y] ifte] dup i"
  # TODO: Optimize with swap2, swap3, cons2, cons3 etc.
  # Primitive Recursion takes as (bottom-to-top) input: 
  # - value to calculate
  # - base case quotation
  # - recursive case quotation.
  rewrite "primrec", "swap [pop pop] swap cons [pop 0 eq?] swap [[dup 1 sub] dip dup i] [[swap] dip] dip [swap] dip swap append [] swap [swap] dip [[swap cons] dip cons] dip cons [ifte] append dup i"
  #rewrite "mul", "[pop pop] [[add] dip] primrec"

  # 3 2 mul
  # 3 + 3

  rewrite "neq?", "eq? not"
  rewrite "zero?", "0 eq?"
  rewrite "one?", "1 eq?"
  rewrite "lt?", "compare -1 eq?"
  rewrite "gt?", "compare 1 eq?"
  rewrite "gte?", "compare -1 neq?"
  rewrite "lte?", "compare  1 neq?"
  rewrite "empty?", "[] compare zero?"
  rewrite "xor", "[dup] dip dup [swap] dip or [and not] dip and"
  rewrite "bxor", "[dup] dip dup [swap] dip bor [band bnot] dip band"
end
