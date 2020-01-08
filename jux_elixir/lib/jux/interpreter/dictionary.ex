defmodule Jux.Interpreter.Dictionary do
  def try_lookup_run(state, token) do
    with {:ok, implementation} <- try_lookup(state, token) do
      new_state = update_in(state.function_stack, fn fs ->
        implementation ++ fs
      end)
      {:ok, new_state}
    end
  end

  def try_lookup(state, token) do
    case state.dictionary[token] do
      nil -> {:error, :not_in_dictionary}
      implementation -> {:ok, implementation}
    end
  end
end
