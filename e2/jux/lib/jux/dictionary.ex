defmodule Jux.Dictionary do
  defstruct [
    definition_count: 0,
    definitions: %{}, # definition reference -> implementation of function definitions.
    names: []        # name -> list of definition references.
  ]


  alias Jux.Builtin

  def new() do
    %__MODULE__{}
    |> add_primitive("puts", &Builtin.puts/1)
    |> add_primitive("dup", &Builtin.dup/1)
    |> add_primitive("pop", &Builtin.pop/1)
    |> add_primitive("swap", &Builtin.swap/1)
    |> add_primitive("lit_int", &Builtin.lit_int/1)
    |> add_primitive("[", &Builtin.start_quotation/1)
    |> add_primitive("dump_stack", &Builtin.dump_stack/1)
    |> add_primitive("dump_state", &Builtin.dump_state/1)
    |> add_complex("test", ["puts", "swap", "dup"])
  end

  def add_word(dictionary, name, implementation) do
    # name_atom = name |> String.to_atom
    # reference = dictionary.definition_count
    # new_definitions = Map.put(dictionary.definitions, reference, implementation)
    # conflicting_refs = dictionary.names[name_atom] || []
    # new_names = [{name, reference} | dictionary.names]
    # %__MODULE__{dictionary | definition_count: reference + 1, definitions: new_definitions, names: new_names}
    dictionary
    |> create_new_word(name)
    |> alter_implementation_of_newest_word(implementation)
  end

  def add_primitive(dictionary, name, implementation) when is_function(implementation) do
    add_word(dictionary, name, implementation)
  end

  def add_complex(dictionary, name, implementation) when is_list(implementation) do
    compiled_implementation =
      implementation
      |> Enum.map(fn name -> get_reference!(dictionary, name) end)
    add_word(dictionary, name, compiled_implementation)
  end

  def create_new_word(dictionary, word_name) do
    reference = dictionary.definition_count

    %__MODULE__{dictionary |
                definitions: Map.put(dictionary.definitions, reference, []),
                definition_count: reference + 1,
                names: [{word_name, reference} | dictionary.names]
    }
  end

  def alter_implementation_of_newest_word(dictionary, implementation) do
    %__MODULE__{dictionary |
                definitions: Map.put(dictionary.definitions, dictionary.definition_count - 1, implementation)
    }
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
