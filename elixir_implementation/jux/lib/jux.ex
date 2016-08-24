defmodule Jux do
  def i(str) do
    final_stack = 
      str
      |> Jux.Parser.parse
      |> IO.inspect
      |> Jux.Evaluator.evaluate
    IO.puts "stack: "<> stack_to_string(final_stack)      
  end

  def sigil_j(str, opts) do
    str
    |> Macro.unescape_string
    |> i
  end

  def stack_to_string(list) do
    list
    |> Enum.map(fn elem -> 
      case elem do 
        _ when is_list(elem) ->
        "[#{stack_to_string(elem)}]"
        _ ->
          inspect(elem)
      end
    end)
    |> :lists.reverse
    |> Enum.join(" ")
  end
end
