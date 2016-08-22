defmodule Jux do
  def i(str) do
    final_stack = 
      str
      |> Jux.Parser.parse
      |> Jux.Evaluator.evaluate
    IO.puts "stack: "<> stack_to_string(final_stack)      
  end

  def sigil_j(str, _opts) do
    i(str)
  end

  def stack_to_string(list) do
    list
    |> Enum.map(fn elem -> 
      case elem do 
        _ when is_list(elem) ->
        "[#{stack_to_string(elem)}]"
        _ ->
          elem
      end
    end)
    |> :lists.reverse
    |> Enum.join(" ")
  end
end
