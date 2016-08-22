defmodule Jux.Evaluator do

  def evaluate(function_stack) do
    evaluate_on(function_stack, [])
  end
  def evaluate_on(function_stack, stack) do
    function_queue = :lists.reverse function_stack
    do_evaluate_on(function_queue, stack)
  end

  defp do_evaluate_on([], stack) do
    stack
  end

  defp do_evaluate_on([literal | rest], stack) when is_integer(literal) or is_binary(literal) or is_float(literal) or is_list(literal) do
    do_evaluate_on(rest, [literal | stack])
  end

  defp do_evaluate_on([identifier = %Jux.Identifier{} | rest], stack) do
    do_evaluate_on(rest, Jux.Identifier.evaluate(identifier, stack))
  end
end
