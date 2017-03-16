defmodule Jux do
  @moduledoc """
  Documentation for Jux.
  """

  def run_without_prelude(string) do
    do_run(string)
    :done
  end

  def run_file(filename) do
    do_run_file(filename)
    :done
  end

  def run(string) do
    {:ok, contents} = File.read("./prelude.jux")
    do_run(contents <> "\n" <> string)
    :done
  end

  defp do_run(string) do
    Jux.State.new(string)
    |> Jux.State.call
  end

  defp do_run_file(filename) do
    {:ok, contents} = File.read(filename)
    do_run(contents)
  end

end
