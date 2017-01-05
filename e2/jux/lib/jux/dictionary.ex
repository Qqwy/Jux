defmodule Jux.Dictionary do
  defstruct [
    definition_count: 0,
    definitions: %{}, # definition reference -> implementation of function definitions.
    names: []        # name -> list of definition references.
  ]


  alias Jux.Builtin

  def new() do
    %__MODULE__{}
    |> add_word("puts", &Builtin.puts/1)
    |> add_word("dup", &Builtin.dup/1)
    |> add_word("pop", &Builtin.pop/1)
    |> add_word("swap", &Builtin.swap/1)
    |> add_word("lit_int", &Builtin.lit_int/1)
    |> add_word("dump_stack", &Builtin.dump_stack/1)
    |> add_word("dump_state", &Builtin.dump_state/1)
    |> add_word("test", ["puts", "swap", "dup"])
  end

  # TODO: Compile implementation.
  def add_word(dictionary, name, implementation) do
    # name_atom = name |> String.to_atom
    reference = dictionary.definition_count
    new_definitions = Map.put(dictionary.definitions, reference, implementation)
    # conflicting_refs = dictionary.names[name_atom] || []
    new_names = [{name, reference} | dictionary.names]
    %__MODULE__{dictionary | definition_count: reference + 1, definitions: new_definitions, names: new_names}
  end

  # @doc """
  # NOTE: Inherently unsafe.

  # Better would be a method that forgets _everything_ up to and including
  # this word.
  # """
  # def remove_word(dictionary, name) do
  #   [reference | prev_refs] = dictionary.names[name]
  #   definitions = Map.delete(dictionary.definitions, reference)
  #   names = Keyword.put(dictionary.names, name, prev_refs)
  #   %__MODULE__{dictionary | definitions: definitions, names: names}
  # end

  def get_implementation_by_name(dictionary, name) do
    ref =
      dictionary
      |> get_reference(name)
    get_implementation(dictionary, ref)
  end

  @doc """
  Returns a function implementation when given a reference to it.
  """
  def get_implementation(dictionary, reference) do
    case dictionary.definitions[reference] do
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

end
