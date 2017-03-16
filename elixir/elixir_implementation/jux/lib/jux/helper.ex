defmodule Jux.Helper do
  @doc """
  Returns the atom version of `str` if it exists.
  If it does not, returns the integer `0` (This is chosen instead of `nil` 
  because `nil` secretly is an atom itself; which would make it impossible 
  to tell the difference between the proper input `"nil"` and the improper input `"this does not exist as atom"`)
  """
  def safe_to_existing_atom(str) do
    str
    |> String.to_existing_atom
  rescue 
    ArgumentError ->
      0
  end
end
