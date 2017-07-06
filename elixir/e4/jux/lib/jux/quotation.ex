defmodule Jux.Quotation do
  defstruct implementation: Okasaki.Deque.empty()

  def new(implementation \\ Okasaki.Deque.empty()), do: %__MODULE__{implementation: implementation}

  def from_list(implementation_list) do
    # TODO It would be even better if this logic is not hard-coded heere,
    # but rather, when something is added to a quotation, it is wrapped in a wrapper
    # that itself knows its name as well as its implementation.
    # For literals, use a `push_literal` function wrapper.
    normalized_impl_list =
      implementation_list
      |> Enum.map(fn
    %__MODULE__{} = quot -> {inspect(quot), fn state -> Jux.Primitive.push(state, quot) end}
        elem                 -> elem
      end)
    %__MODULE__{implementation: Okasaki.Deque.new(normalized_impl_list)}
  end

  def push(quotation, instruction) do
    %__MODULE__{implementation: Okasaki.Deque.insert_right(quotation.implementation, instruction)}
  end

  def unshift(quotation, instruction) do
    %__MODULE__{implementation: Okasaki.Deque.insert_left(quotation.implementation, instruction)}
  end

  def append(quotation, list) do
    Enum.reduce(list, quotation, fn elem, quotation ->
      quotation
      |> push(elem)
    end)
  end

  def implementation(quotation) do
    # IO.inspect(quotation, structs: false, label: "Quotation.implementation")
    quotation.implementation
    |> Okasaki.Deque.to_list
    # |> :lists.reverse
  end

  def compiled_implementation(quotation) do
    quotation
    |> implementation
    |> Enum.map(&elem(&1, 1))
  end

  defimpl Inspect do
    def inspect(quotation, opts) do
      "[ " <>
      (
        quotation
        |> Jux.Quotation.implementation
        |> Enum.map(&elem(&1, 0))
        |> Enum.join(" ")
      )
      <>" ]"
    end
  end

  defimpl String.Chars do
    def to_string(quotation), do: inspect(quotation)
  end
end
