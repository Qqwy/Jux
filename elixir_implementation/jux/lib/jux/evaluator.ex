defmodule Jux.Evaluator do

  def evaluate(function_stack) do
    evaluate_on(function_stack, [])
  end
  def evaluate_on(function_stack, stack, known_definitions \\ %{}) do
    function_queue = :lists.reverse function_stack
    do_evaluate_on(function_queue, stack, known_definitions)
  end

  defp do_evaluate_on([], stack, known_definitions) do
    {stack, known_definitions}
  end

  defp do_evaluate_on([literal | rest], stack, known_definitions) when is_integer(literal) or is_binary(literal) or is_float(literal) or is_list(literal) do
    do_evaluate_on(rest, [literal | stack], known_definitions)
  end

  defp do_evaluate_on([identifier = %Jux.Identifier{name: "__PRIMITIVE__"} | rest], stack, known_definitions) do
    raise "A function is missing a primitive implementation. Rest of function stack: #{inspect(rest)}"
  end

  defp do_evaluate_on([identifier = %Jux.Identifier{name: "def"} | rest], stack, known_definitions) do
    #{updated_stack, updated_fun_queue} = Jux.Identifier.evaluate(identifier, stack, rest, known_definitions)
    #IO.puts "Defining a function!"
    [fun_implementation_quot, fun_documentation, fun_name | updated_stack] = stack
    IO.inspect(fun_implementation_quot)
    if !is_list(fun_implementation_quot) do
      raise "Function definition for #{fun_name} (#{inspect(fun_implementation_quot)}) is not a quotation!"
    end 
    known_definitions = Map.put_new(known_definitions, fun_name, fun_implementation_quot |> Jux.Identifier.fully_expand(known_definitions) |> :lists.reverse)
    #IO.inspect known_definitions
    do_evaluate_on(rest, updated_stack, known_definitions)
  end

  defp do_evaluate_on([identifier = %Jux.Identifier{} | rest], stack, known_definitions) do
    {updated_stack, updated_fun_queue} = Jux.Identifier.evaluate(identifier, stack, rest, known_definitions)
    do_evaluate_on(updated_fun_queue, updated_stack, known_definitions)
  end

end
