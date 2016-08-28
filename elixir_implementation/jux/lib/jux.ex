defmodule Jux do
  def i(str, load_standard_library? \\ true, show_types \\ false) do
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
    IO.puts "stack: "<> stack_to_string(final_stack, show_types)
    # IO.puts "known_definitions:" <> inspect(known_definitions)
    {final_stack, known_definitions}
  end

  def sigil_j(str, opts) do
    show_types = Enum.any?(opts, fn x-> x== ?t end)
    load_standard_library? = !Enum.any?(opts, fn x-> x== ?e end)
    str
    |> Macro.unescape_string
    |> i(load_standard_library?, show_types)
    :ok
  end

  def i_file(file_path, load_standard_library? \\ true) do
    {:ok, file_contents} = File.read(file_path)
    i(file_contents, load_standard_library?)
  end

  def load_standard_library() do
    i_file("stdlib/stdlib.jux", false)
  end

  def stack_to_string(list, show_types \\ false) do
    list
    |> Enum.map(fn labeled_elem -> 
      case labeled_elem do
        {elem, "String"} when is_list(elem) and show_types->
        "\"#{jux_string_to_elixir_charlist(elem)}\"(String)"
        {elem, "String"} when is_list(elem)->
        "\"#{jux_string_to_elixir_charlist(elem)}\""
        {elem, elem_type} when is_list(elem) and show_types->
        "[#{stack_to_string(elem, show_types)}](#{elem_type})"
        {elem, elem_type} when is_list(elem) ->
        "[#{stack_to_string(elem)}]"
        {elem, elem_type} when show_types ->
          "#{inspect(elem)}(#{elem_type})"
        {elem, elem_type} ->
          "#{inspect(elem)}"
        elem ->
          # This case should (normally?) not happen.
          inspect(elem)
      end
    end)
    |> :lists.reverse
    |> Enum.join(" ")
  end

  def elixir_charlist_to_jux_string(charlist) do
    charlist
    |> Enum.map(fn int -> 
      {int, "Integer"}
    end)
  end

  def jux_string_to_elixir_charlist(string) do
    string
    |> Enum.map(fn {int, "Integer"} ->
      int
    end)
  end
end
