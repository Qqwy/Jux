defmodule Jux.Helper do
  def declawed_string_to_atom(str) do
    try do
      {:ok, String.to_existing_atom(str)}
    rescue
      ArgumentError ->
        {:error, :unexistent_atom}
    end
  end
end
