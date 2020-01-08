defmodule Jux.Interpreter.Primitives do
  # Necessary to make `function_exported?` work
  require Jux.Primitives

  def try_lookup_run(state, token) do
    with {:ok, atom} <- try_lookup(token) do
      new_state = apply(Jux.Primitives, atom, [state])
      {:ok, new_state}
    end
  end

  def try_lookup(token) do
    with {:ok, atom} <- Jux.Helper.declawed_string_to_atom(token),
         true <- function_exported?(Jux.Primitives, atom, 1) do
      {:ok, atom}
    else
      false ->
        {:error, :not_a_primitive}
      {:error, :unexistent_atom} ->
        {:error, :not_a_primitive}
    end
  end
end
