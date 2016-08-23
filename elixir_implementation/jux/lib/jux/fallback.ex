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


  # Basic
  rewrite "noop", "" #does nothing.
  rewrite "id", "[] dip" # No-op, but fails if stack is empty.

  # Stack manipulation
  rewrite "swapd", "[swap] dip"
  rewrite "swap2", "swap swapd"
  rewrite "popd", "[pop] dip"
  
  rewrite "dupd", "[dup] dip"
  rewrite "dupdd", "[dupd] dip"
  rewrite "get2", "dupd swap"
  rewrite "get3", "[get2] dip swap"
  rewrite "get4", "[get3] dip swap"
  rewrite "dup2", "get2 get2"
  rewrite "dup3", "get3 get3 get3"
  rewrite "dup4", "get4 get4 get4 get4"

  rewrite "flip", "swapd swap swapd" # 1 2 3 -> 3 2 1
  rewrite "flip4", "swap [flip] dip swap" # 1 2 3 4 -> 4 3 2 1
  rewrite "flip5", "swap [flip4] dip swap" # 1 2 3 4 5 -> 5 4 3 2 1


  # Combinators
  rewrite "dip2", "swap [dip] dip"
  rewrite "dip3", "swap [dip2] dip"
  rewrite "dip4", "swap [dip3] dip"

  rewrite "i", "dup dip pop"
  rewrite "keep_i", "dup [i] dip"
  rewrite "b", "[i] dip i"
  rewrite "m", "dup i"
  # k
  # c
  # w
  # y

 
  # Arithmetic
  rewrite "inc", "1 add"
  rewrite "dec", "1 sub"

  rewrite "odd?", "1 band truthy?"
  rewrite "even?", "odd? not"



  # Conditionals
  rewrite "if", "[] ifte"
  rewrite "unless", "[] swap ifte"

  rewrite "ifeqte", "[[lift [eq?] append] dip2 ifte"
  rewrite "ifneqte", "[[lift [neq?] append] dip2 ifte"
  rewrite "ifzte", "[[[zero?]] dip2 ifte"
  rewrite "ifnzte", "[[[zero? not]] dip2 ifte"


  # Comparison
  rewrite "falsy?", "not"
  rewrite "truthy?", "falsy? not"
  rewrite "neq?", "eq? not"
  rewrite "zero?", "0 eq?"
  rewrite "one?", "1 eq?"
  rewrite "lt?", "compare -1 eq?"
  rewrite "gt?", "compare 1 eq?"
  rewrite "gte?", "compare -1 neq?"
  rewrite "lte?", "compare  1 neq?"
  rewrite "empty?", "[] compare zero?"

  rewrite "max", "[gt?] [pop] [popd] ifte"
  rewrite "min", "[lt?] [pop] [popd] ifte"

  # Quotations
  rewrite "reverse_cons", "swap cons"
  rewrite "reverse_uncons", "uncons swap"
  
  rewrite "lift", "[] reverse_cons"
  rewrite "lift2", "[] swapd reverse_cons reverse_cons"
  rewrite "unlift", "uncons popd"
  rewrite "unlift2", "uncons [uncons popd] dip"

  rewrite "length", "0 [inc] reduce"
  rewrite "reverse_append", "[cons] reduce"
  rewrite "append", "swap reverse_append"
  rewrite "map", "[] swap [cons] append reduce"
  # TODO rewrite "reverse", ""
  rewrite "flatten", "[] [append] reduce" # TODO: Improve

  rewrite "sum", "0 [add] reduce"
  #rewrite "product", "1 [mul] reduce"
  rewrite "list_max", "uncons [max] reduce"
  rewrite "list_min", "uncons [min] reduce"
  rewrite "list_max_min", "uncons dup lift2 [dup [unlift2] dip2 swapd max [min] dip lift2] reduce"

  # Boolean
  rewrite "xor", "[dup] dip dup [swap] dip or [and not] dip and"

  # Bitwise  
  rewrite "bxor", "[dup] dip dup [swap] dip bor [band bnot] dip band"

  # Recursion
  #rewrite "Z X Y primrec", "Z [[ pop 0 eq?] [pop pop X] [[dup 1 sub] dip dup i Y] ifte] dup i"
  # TODO: Optimize with swap2, swap3, cons2, cons3 etc.
  # Primitive Recursion takes as (bottom-to-top) input: 
  # - value to calculate
  # - base case quotation
  # - recursive case quotation.
  rewrite "primrec", "swap [pop pop] swap cons [pop 0 eq?] swap [[dup 1 sub] dip dup i] [[swap] dip] dip [swap] dip swap append [] swap [swap] dip [[reverse_cons] dip cons] dip cons [ifte] append dup i"
  #rewrite "mul", "[pop pop] [[add] dip] primrec"

  # 3 2 mul
  # 3 + 3
end
