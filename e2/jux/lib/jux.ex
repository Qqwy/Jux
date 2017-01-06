defmodule Jux do

  @doc """
  Runs the Jux program given as string `program`.
  """
  def run(program) do
    program
    |> String.trim_leading
    |> Jux.State.new
    |> Jux.Parser.parse_token
    |> Jux.State.call
  end
end
