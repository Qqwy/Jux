defmodule Jux do
  @moduledoc """
  Documentation for Jux.
  """

  def run(string) do
    Jux.State.new(string)
    |> Jux.State.call
  end
end
