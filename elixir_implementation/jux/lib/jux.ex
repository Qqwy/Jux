defmodule Jux do
  def i(str, load_standard_library? \\ true) do
    parsed_representation = Jux.Parser.parse(str)

    {stack, known_definitions} = 
      if !load_standard_library? do
        {[], %{}}
      else
        {stack, known_definitions} = Jux.load_standard_library
        if stack != [] do
          raise "Stack is not nil after loading the standard library! `#{stack_to_string(stack)}`"
        end
        {stack, known_definitions}
      end

    {final_stack, known_definitions} = Jux.Evaluator.evaluate_on(parsed_representation, stack, known_definitions)
    #IO.inspect({final_stack, known_definitions})
    IO.puts "stack: "<> stack_to_string(final_stack)
    # IO.puts "known_definitions:" <> inspect(known_definitions)
    {final_stack, known_definitions}
  end

  def sigil_j(str, opts) do
    str
    |> Macro.unescape_string
    |> i
    :ok
  end

  def i_file(file_path, load_standard_library? \\ true) do
    {:ok, file_contents} = File.read(file_path)
    i(file_contents, load_standard_library?)
  end

  def load_standard_library() do
    i_file("stdlib/stdlib.jux", false)
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
