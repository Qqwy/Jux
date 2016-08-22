defmodule Jux.Primitive do
  @moduledoc """
  Defines the native primitive function implementation known to this Elixir implementation.

  These are the 'building blocks' used in all programs.
  Anything not in here is tried to be converted to primitive function calls by use of the standard-library fallback rewrite rules.
  """

  # Primitive Stack Manipulation

  def dup([x | xs]) do
    [x, x | xs]
  end

  def swap([x, y | xs]) do
    [y, x | xs]
  end

  def pop([x | xs]) do
    xs
  end

  # Arithmetic

  def add([b, a | xs]) do
    [a + b | xs]
  end

  def sub([b, a | xs]) do
    [a - b | xs]
  end

  # Boolean

  def unquote(true)(xs) do
    [true | xs]
  end

  def unquote(false)(xs) do
    [false | xs]
  end

  def not(xs)
  def not([false | xs]), do: [true | xs]
  def not([_ | xs]), do: [false | xs]

  def unquote(:or)([false, false | xs]), do: [false | xs]
  def unquote(:or)([_    , _     | xs]), do: [true | xs]

  def unquote(:and)([false, _     | xs]), do: [false | xs]
  def unquote(:and)([_    , false | xs]), do: [false | xs]
  def unquote(:and)([_    , _     | xs]), do: [true | xs]


end