defmodule Jux.Interpreter.Primitives do
  # Necessary to make `function_exported?` work
  require Jux.Primitives

  def try_lookup_run(state, token) do
    with {:ok, atom} <- try_lookup(state, token) do
      run(state, atom)
    end
  end

  def try_lookup(_state, token) do
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

  # TODO use error-tuples instead in the primitive implementation maybe?
  def run(state, atom) when is_atom(atom) do
    try do
      {:ok, apply(Jux.Primitives, atom, [state])}
    catch problem ->
        {:error, problem}
    end
  end
end
