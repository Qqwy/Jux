defmodule Jux do

  @doc """
  Runs the Jux program given as string `program`.
  """
  def run(program) do
    Jux.State.new(program <> " ")
    |> Jux.Parser.parse_token
    |> Jux.State.call
  end
end
