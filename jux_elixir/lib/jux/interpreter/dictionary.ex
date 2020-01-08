defmodule Jux.Interpreter.Dictionary do
  def try_lookup_run(state, token) do
    with {:ok, implementation} <- try_lookup(state, token) do
      run(state, implementation)
    end
  end

  def try_lookup(state, token) do
    case state.dictionary[token] do
      nil -> {:error, :not_in_dictionary}
      implementation -> {:ok, implementation}
    end
  end

  def run(state, impl) when is_list(impl) do
    new_state = update_in(state.function_stack, fn fs ->
      impl ++ fs
    end)
    {:ok, new_state}
  end
end
