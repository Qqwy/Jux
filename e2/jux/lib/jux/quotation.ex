defmodule Jux.Quotation do
  defstruct implementation: :queue.new

  def new(implementation \\ :queue.new), do: %__MODULE__{implementation: implementation}

  def push(quotation, instruction) do
    %__MODULE__{implementation: :queue.cons(instruction, quotation.implementation)}
  end

  def unshift(quotation, instruction) do
    %__MODULE__{implementation: :queue.snoc(quotation.implementation, instruction)}
  end

  def implementation(quotation) do
    quotation.implementation
    |> :queue.to_list
    |> :lists.reverse
  end

  defimpl Inspect do
    def inspect(quotation, _opts) do
      "[ " <>
      (
        quotation
        |> Jux.Quotation.implementation
        |> Enum.join(" ")
      )
      <>" ]"
    end
  end
end
