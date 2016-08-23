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
end