defmodule Jux.Dictionary do
  defstruct [
    definition_count: 0,
    runtime_definitions: %{}, # runtime definition reference -> implementation of function definition (as list).
    compiletime_definitions: %{}, # compile-time definition reference -> implementation of function definition (as list).
  names: []        # name -> definition reference (integer).
  ]

  @doc """
  Defines a new word with the given implementation,
  but stores it as 'nil' until renamed.
  """
  def define_new_word(dictionary, implementation, compiletime_implementation) do
    reference = dictionary.definition_count

    %__MODULE__{dictionary |
                runtime_definitions: Map.put(dictionary.runtime_definitions, reference, implementation),
                compiletime_definitions: Map.put(dictionary.compiletime_definitions, reference, compiletime_implementation),
                definition_count: reference + 1,
                names: [{nil, reference} | dictionary.names]
    }
  end

  @doc """
  Gives a different name to the last word (which should be created using `define_new_word` before).
  """
  def rename_last_word(dictionary, name) do
    [{_, reference} | rest] = dictionary.names
    dictionary
    |> Map.put(:names, [{name, reference} | rest])
  end

  @doc """
  Returns the implementation that can be found in the dictionary
  looking up the given name.
  """
  def get_implementation_by_name(dictionary, name) do
    ref = get_reference(dictionary, name)
    get_implementation(dictionary, ref)
  end

  @doc """
  Returns a function implementation when given a reference to it.
  """
  def get_implementation(dictionary, reference) do
    case dictionary.runtime_definitions[reference] do
      nil -> :error
      ref -> {:ok, ref}
    end
  end

  @doc """
  Returns the reference that belongs to the given name.
  """
  def get_reference(dictionary, name) do
    case :lists.keyfind(name, 1, dictionary.names ) do
      {_name, ref} ->
        {:ok, ref}
      _ ->
        :error
    end
  end
  def get_reference!(dictionary, name) do
    {:ok, ref} = get_reference(dictionary, name)
    ref
  end

  @doc """
  Only used for debugging/pretty printing.
  Returns the names of the given references
  by a reverse lookup.
  """
  def get_reference_name(dictionary, reference) do
    ref_to_name_map = for {k, v} <- dictionary.names , into: %{}, do: {v, k}
    ref_to_name_map[reference]
  end
end
