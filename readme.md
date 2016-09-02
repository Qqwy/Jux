This is the main repository/project folder of Jux.

Jux is a simple *stack-based concatenative functional* programming language.
Jux has two intertwined goals:

- Be a very simple basic language that is as easy as possible to implement on any target platform.
- Be an easy target for other languages to compile to, not sacrificing features along the way.


To be able to live up to both of these goals, Jux defines a very small set of literals and functions that *have* to be defined by an implementation, but has a much larger standard library with 'fallback' implementations that are used by default. Target implementations can be made more efficient by building native versions of more and more of these standard library functions.

The same holds true for data types: The literal data types a target *has* to implement are `int`, `string`, `quotation`(linked lists), `symbol`(a name with a constant integer value). The other supported data types (`tuple`(pairs, triples, etc; fixed-size arrays of values), `dict`(an associative key->value store ) and `tree` are by default implemented on top of lists.)

# Definition

Jux is a _functional, minimalistic, concatenative, homoiconic, nominally-typed_ programming language:

- functional: Everything in Jux is a function, taking the current environment as input, and returning a changed environment as output.
- minimalistic: Jux designed to be as simple as possible to implement. There are only +- 18 primitive instructions(most of which are trivial to implement), two literal types(integers and linked lists called 'quotations') and the rest of the interpreter/compiler is completely straightforward. Jux works without needing any behind-the-scenes data manipulation (i.e. no garbage collection necessary).
- concatenative: To combine multiple functions, the result is passed left-to-right.
- homoiconic: Jux's source maps neatly unto what happens on the stack. There also is no difference between a snippet of souce code and a linked list containing some other type of data.
- nominally typed: All values in Jux have a type, which basically is a 'label' which can be queried and certain low-level operations might alter. The advantage is that a certain implementation might decide to alter one of Jux's types from a quotation-based implementation to a lower-language literal (which is more efficient) without breaking anything.

## Inspiration

Jux is inspired by the concatenative languages [**Joy**](https://web.archive.org/web/20111007025556/http://www.latrobe.edu.au/phimvt/joy/j02maf.html)(WebArchive link; original website is down) and [**Cat**](https://web.archive.org/web/20140720143526/http://www.cat-language.com/index.html)(WebArchive link; original website is down).


# Roadmap

- Old Ruby implementation prototype: 100%; _(not in this repository)_
- Flesh out this Readme: 65%;
- Elixir implementation version: 0.2;
- New Ruby implementation: 0%;

- [x] Think about custom function definitions: Syntax: `"name" "documentation" [implementation] def`
- [x] Think about fallback rewrite function implementations: 
  - > A Fallback rewrite _can_ contain its own name, as long as this happens inside a quotation, so we can expand a rewrite rule all at once without creating an infinite loop. These kinds of recursive rewrites with the same name used inside a quotation are however very useful sometimes.
  - [x] All of these functions need documentation just like normal functions.
    - Have definitions of all functions, including primitive ones.
    - primitive function definitions contain a quotation with `__PRIMITIVE__` inside, which itself is a defined no-op, but handled by the evaluator to raise an error when encountered during execution.
  

- Think about efficiency:
  - [x] Fully expand fallback rewrites, so when a fallback definition is found, only a single rewrite step is necessary.
  - Custom rewrite rules to be applied before and after expanding that increase efficiency; Things like:
    - How do we make them? When/how do we run them?
    - examples:
      - `reverse length ==> length`
      - `dup pop ==> `
      - `dup swap ==> dup`
      - `[] i ==> `
      - `0 + ==> `
      - _see the [Mathematical foundations of Joy](https://web.archive.org/web/20111007025556/http://www.latrobe.edu.au/phimvt/joy/j02maf.html) for more examples of rewrite rules in concatenative languages_

Minimize core language:

Current required operations:

- the integer, string and quotation literals.
- `dup, pop, swap` Stack manipulation.
- `dip` Combinators.
- `cons, uncons` Quotation manipulation.
- `add, sub` Integer arithmetic.
- `ifte` Conditionals.
- `eq?` Equality.
- `compare` Comparisons of ordering.
- `string_concat` Combine two strings. TODO: Strings as integer quotations would mean that this is not needed.
- `print` Output to STDOUT.
- `bnot, band, bor` Bitwise operations. TODO: Can these be emulated? How necessary are they?

Probably going to add:

- Some way to listen to STDIN.
- Some way to access the file system.
- Some way to talk to external programs?
- Some way to crash with an error message.

Here is in greater detail what certain functions are used for:

- core stack manipulation: `dup pop swap`.
- core stack manipulation combined with `dip` is enough to define the following combinators:
  - `i` (interpret)
  - `b` (interpret lower, then upper)
  - `k` (interpret, then put source of interpretation on top)
  - `m`
  - `w`
- comparisons done by primitive functions `compare` and `eq?`, which are enough for `eq?, neq? lt?, lte?, gt?, gte?, zero?, one?, empty?`. Together with math used for `even?, odd?`.
- `ifte` to allow conditionals.
  - together with above enough for many recursive definitions, as seen below.
- fallback (slow) integer multiplication/division/modulo built on recursion with `add`/`sub`.
  - TODO: `pow, isqrt, gcd, lcm`.
- boolean operations: based on [NAND-logic](https://en.wikipedia.org/wiki/NAND_logic), so with only `nand` we can define `nand, not, and, or, nor, xor`.
  - because of the truthiness nature of these operations, defining `true` and `false` is not necessary, as they are trivially `[] not not` and `[] not`, respectively.
  - maybe something similar can be done with bitwise operators?
- `cons` and `uncons`, together with comparisons, `ifte` and `dip` is enough for recursion through lists, which allows: `foldl, foldr, append, reverse_append, backwards_append, map, length, any?, all?, filter, reject, sum, product`
- recursion also allows nice definitions for functions like `factorial`, `triangular`, etc.

# Future Goals

- Create a way to use rewrite rules to enhance efficiency; things like `reverse length === length`
- Self-hosting.
- Multiple implementations.
- Explore data types, and how to 'fake' more advanced data types when you only have integers and quotations.
- Explore differences between string-as-list and string-as-byte_arr for implementation/efficiency.
- Explore the advantages/drawbacks of a bytecode variant of Jux.
- Explore (dependently?) statical typing and if/how it might work with a concatenative language.

________________


# Easy to implement

A bare-bones (also called a **level-0**) implementation has to contain at least:

- The literals:
  - `Integer` (`[+-]?\d+`), an integer of at least 32-bits precision. If you can use Bignums, that is a plus, as Jux does not check for overflow. If your target platform cannot use at least 32-bits precision, it will be a reduced level -1 implementation.
  - **TODO** `Float` (`[+-]?\d+.\d+`), a float of at least 24-bits precision, preferably following the IEEE 754 standard. If your target does not support floating-point arithmetic, it will be a reduced level -1 implementation.
  - `String` (`".*"`, escaping is possible with `\"`.). Contains all characters between the quotes as string. The choice has been made to _not_ make this equal to a list of character codepoints, because those charlists have much worse performance for many common problems and algorithms.
  - `Function` (`[a-z][\w]*[?!]?`). These are the names of operations we want to perform. A function name either refers to one of the built-in primitive functions, or a custom function that was defined earlier in the program (or possibly in the standard library). As you will see below, it is necessary to keep a reference to these names before applying the functions, because of the way how quotations work.

In actuality, Integers and Strings can also be considered functions, that take zero parameters as input and push their inner value as output. In most implementations, it makes most sense to just take the literal and copy it to the stack when applicable, though.

  - `Quotation`. (`\[.*\]`, can be nested; contents have to be a proper Jux expression. ) Quotations are linked lists of arbitrary items. In a program, they can be manipulated by adding more elements to it or removing elements. Quotations are also used for metaprogramming and control flow: By putting functions (remember, literals are in fact also functions) inside them, one can pass one or multiple functions around without evaluating them right away.


A compiler/interpreter needs to:

- Take a program as string as input.
- Parsing the above literals to an internal in-memory representation called the _function queue_, filtering any whitespace, newlines and comments.
- To now evaluate the program:
- Initialize the empty memory stack.
- while the _function queue_ is not empty:
  - Take the function at the beginning of the _function queue_, and call it with the stack as input. 
    - (in practice it makes most sense to simply 'copy over' Integers, Strings and Quotations from the beginning of the _function queue_ to the top of the _stack_, only really calling Functions)
    - If it is a function, try to use custom implementation, if it exists. If it doesn't, fall back to one of the fallback rewrite rules that alter the _function queue_.
  - Replace the current stack with the stack that the function returned as output.

## Level-0 required primitive functions:

### Stack manipulation

- `pop`: Removes the top value of the stack. Throws an error if there is nothing in the stack.
- `dup`: Duplicates the top value on the stack. Throws an error if there is nothing in the stack.
- `swap`: Swaps the top item with the item below it. Throws an error if there are less than two items on the stack.

The standard library extends on this with multiple variations of swapping, duplicating etc.

### Metaprogramming Combinators

- `dip`: Take the quotation at the top of the stack. Temporarily store and remove the value right below it elsewhere. Execute the quotation on the rest of the stack. Afterwards, put the stored value back on top.

The standard library extends on this with:
- `i`: Interpret/evaluate the quotation on top of the stack.
- `b`: Take the two quotations on top of the stack, and interpret/evaluate them in reverse order.
- TODO `w`
- TODO `k` 
- TODO `c`
- TODO `y`: Useful to make recursive definitions.

### Comparisons

- `compare`: Pops the top two items, `a` and `b` (`a` being the item originally on top). Puts `-1` on top of the stack if `b` is smaller than `a`, `0` if they are equal, and `1` if `a` is larger than `b`.

Note that _all_ Jux values are comparable with each other; They form a monoid. This is useful to easily create sorting functions and associative lookups without extra overhead or edge cases.

Comparisons have the following order:
`Integer/Float < Boolean < Function < String < Quotation`
- An Integer/Float is compared by its numerical value.
- Comparison between Functions and comparisons between Strings is done by using 'dictionary order'.
- Quotations are compared element-wise; if the first elements are the same, the second elements are considered, etc. A shorter quotation that has the same prefix as a longer quotation is smaller.

The standard library extends on this with:
- `eq`: Pops the top two items. Puts `true` if top two items are equal, otherwise `false`.
- `neq`: Pops the top two items. Puts `false` if top two items are equal, otherwise `true`.
- `lt`, `gt`, `lte`, `gte`, `zero?`, `one?`
- `empty?`, which is true if the element on top is an empty list.

### Basic Conditionals
- `ifte`: Takes three quotatios from the top of the stack: The bottommost is the condition that is checked. After checking the condition, the stack is returned to its original state. If the result of this condition is anything other than `false`, the middle quotation (the _then_-part) is interpreted/evaluated. Otherwise, the topmost quotation (the _else_-part) is interpreted/evaluated.

### Basic Integer Arithmetic

- `add`: Pops the top two elements `a` and `b` (`a` being the item originally on top) and pushes the result of performing integer addition `b + a`.
- `sub`: Pops the top two elements `a` and `b` (`a` being the item originally on top) and pushes the result of performing integer addition `b - a`.

The standard library extends on this with:
- `inc`
- `dec`
- TODO `mul`
- TODO `pow`
- TODO `div`
- TODO `gcd`
- TODO `lcm`
- TODO `fact`
- TODO `fib`
- TODO `isqrt`

Maybe more?

### Boolean
- `true`: Should push a value representing boolean `true` to the stack.
- `false`: Should push a value representing boolean `false` to the stack.

### Logic Operations
- `not`: Pops top of the stack. Pushes `true` if the top of the stack was `false`, `false` otherwise.
- `or`: Pops the top two elements `a` and `b` (`a` being the item originally on top) Pushes `false` if both `a` and `b` are `false`, `true` otherwise.
- `and`: Pops the top two elements `a` and `b` (`a` being the item originally on top) Pushes `false` if at least one of `a` and `b` are `false`, `true` otherwise.

As can be seen, anything except `false` is considered truthy in Jux.

The standard library extends on this with:
- `xor`: Pops the top two elements `a` and `b` (`a` being the item originally on top) Pushes `false` if exactly one of `a` and `b` is `false`, `true` otherwise.


### Bitwise operations
- `bnot`: Pops top of the stack. Pushes the bitwise complement of that Integer.
- `bor`: Pops the top two elements `a` and `b` (`a` being the item originally on top). Pushes the bitwise or of these two Integers. 
- `band`: Pops the top two elements `a` and `b` (`a` being the item originally on top). Pushes the bitwise and of these two Integers.

The standard library extends on this with:
- `bxor`: Pops the top two elements `a` and `b` (`a` being the item originally on top). Pushes the bitwise xor of these two Integers.


### Quotation/List operations

- `cons`: Pops the top of the stack `a` and the quotation `q` just below it, and returns a new quotation `q2` where `a` is the final item in `q`.
- `uncons`: Pops the top of the stack `q2`, and extracts the final item `a`. Pushes `q` which is `q2` without this item. Then pushes `a`.
- `foldl`: Given a quotation `q`, a starting accumulator `acc`, and a quotation-list `l` to perform on:
  - Pushes `acc`.
  - Pushes the first (leftmost) value in `l`
  - Evaluates `q`
  - Pushes the next value in `l`.
  - Evaluates `q`
  - etc, until the list is empty.

The standard library extends on this with:
- `reverse`: Reverses a list
- `foldr`: Folds a list, starting at the rightmost end.
- `append`: Concatenates two quotations into one.
- `length`: Returns the number of items in a quotation.
- `map`: Maps a quotation `q` over each of the elements in the list `l`, returning a new list.
- `sum`: Calculates the arithmetic sum of a list of integers.
- TODO `product`: Calculates the arithmetic product of a list of integers.

### String operations
- `to_string`: Returns a string representation of the literal on top:
  - for Strings, this is themselves, encapsulated in `""`.
  - for Integers/Floats, this is their digit representation.
  - for unapplied Functions (which might occur in quotations), this is their name.
  - for quotations, this is `[` followed by the space-delimited `to_string` results of its contents, followed by `]`.

- `string_concat`: Concatenates two strings into one.

### Basic Output
- `print`: Prints the string on top of the stack to STDOUT.

The standard library extends on this with:
- `puts`: Prints the string on top of the stack to STDOUT, followed by a newline.

### Basic Input
**TODO**


## Level 1

### Advanced data types
**TODO**


# Syntax:

### Whitespace

Whitespace (including tabs and newlines) is ignored, but used to separate below expression types, as well as to improve human readability.

### Comments

Single-line comments start with `#` and continue until the end of the line.

### Literals
The following literal values are accepted anywhere in the program:

- integers
- floats
- strings, delimited with `"`. These should escape `\n`, `\t`, etc. Quotes themselves can be escaped with `\"`.
- quotations. These are lists, delimited with `[` and `]`. The contents of a quotation should be parsed, but immediately evaluated or expanded. Quotations can be nested. `[]` is an empty quotation.

### Identifiers
Identifiers, which are names of functions. The first character of an identifier has to be alphabetic or an underscore. All other characters can be alphanumeric, underscores or `.`. Identifiers are allowed to end on `?` or `!`.

An example of above rules in practice:

```
# This is a comment

1 2 3.0 "foo" dup swap [4 5 pop "bar"] # This is another comment
i pop [42]
```

### Defining functions
To define a function, the built-in `def` function can be used: `"functionname" "documentation" [function implementation here] def`. For clarity, this is usually written as:

```
"xor"
  "
  Calculates the boolean XOR of the top two arguments.
  "
  [
    dup2
    or            # get 'or' of top two arguments
    [and not] dip # get 'nand' of bottom two arguments'
    and           # only true if both of the above are true
  ] 
def
```

As can be seen, no special syntax is necessary to parse this.


## To think about:

- Heredoc multiline strings?
- Do/don't have multiline comments?














## Custom DataType System

Idea: Data Types built on Records:

- New syntax: `:foo` === `[foo] uncons popd`. Puts a single identifier on the stack without evaluating it. Not _required_, but a lot nicer for below explanations. Could also be used for function names in normal `def` statements.
- Namespaces are used to keep the language explicit and to prevent name clashes. To keep the language simple, _only conventions_ enforce the use of namespaces. `redef`ining a function in a namespace you're not working on is possible (and required for some inner workings of below things), but greatly frowned upon.
  - If there is a way to enforce this on language-level, or have certain implementations enforce this once they are mature enough, I would love to know.

- CDTs are 'just' quotations, where the header is an identifier; the Record's Type.
- This identifier is implemented as a function which constructs the CDT itself. (so `2 0 Point` ==> `[2 0 Point]`, and `[2 0 Point] i` === `[2 0 Point]`)
- A function (`Typename.__ancestors__` e.g. `Point.__ancestors__`) that returns a list of all the (super)types a CDT implements.
  - implemented using `to_string`, `string_append` and `to_identifier`.
  - This function's definition is updated every time this type is listed as being part of a supertype.
    - take old function result (list of supertypes)
    - add new supertype to end
    - remove duplicates from result
    - use this new list in new definition. (`redef`)
- Allow the definition of dispatching multimethods, which take the type of the input value, and then attempt to dispatch to an implementation of the desired function name.
  - Check for implementations using `callable?` on each of the supertype function implementations, e.g. `:Circle.Protocol.radius callable?`, then call the first one that exists.
- Allow similar multimethods for functions with multiple inputs:
  - Protocol for custom Comparisons of CDTs with each other; Only needs a single implementation for two-way comparisons.



New required functions for this stuff:
- `callable?` -> True if identifier is implemented as function.
- `to_string`/`to_identifier` -> turns anything to a string, turns a string to an identifier (as long as it is a _valid_ identifier!)
- `redef` -> defines a function, possibly overriding an already-existing definition.
  - maybe `def` could be defined in terms of `redef` and `callable`?




________________

System overview:

A Jux implementation environment consists of two parts:

## 1. the Stack. 
This is a linked-list esque structure (the head of the stack should be available in O(1), the other end of the stack might be available in O(n)). All data that is being calculated arrives on the stack.



## 2. The HashTable with Identifier Definitions
This hash table stores the implementations that certain identifiers have.
In other words, it gives certain identifiers a 'meaning'.

This HashTable is altered by the primitive `def`, `redef` or `undef` operations. Furthermore, the `callable?` primitive checks if a certain identifier is a key in the hash table.

HashTable Implementations are used both to define ordinary functions, as well as auxillary information about e.g. data types; 

Data stored here is _not_ garbage collected. It stays in here until explicitly `undef`ined.

## (3. The Function Queue)
This is a _queue_ filled with the not-yet consumed operations that will be executed on the stack. An interpreter usually first parses a source code file, and reads it into this in-memory list.

For some implementations, it might make most sense to first read the source file in a linked list (where the head is the lastly-read operation), and then reverse this list before starting execution.

The head of the Function Queue is changed when:

- An identifier with a non-native implementation is encountered. At this time, the identifiers making up its implementation are pushed to the front of the function queue (also known as 'unshifting').
- A quotation is passed in a Combinator: This unshifts the contents of this quotation to the front of the Function Queue (so that the tail-most part of the quotation is the new front of the queue, and the element originally at the head of the quotation is the element just on top of the original next function).

The Function Queue is an implementation 'artefact' and not considered to really be part of the current environment. Rather, it is a list of future steps to change the current environment by. There is no way for any Jux function to directly access any part of the Function Queue. The only thing that might happen, is for a quotation

## 'Purely' Functional?

Most Jux functions/operations are purely functional, as they take the current environment (Stack + HashTable), and return a new environment (Stack+HashTable).

The only exceptions to this are functions that deal with input/output:

- `print`
- STDIO-stuff that hasn't been created yet.

# STDIO:

- `fopen` opens a stream to the file at the given filename.
- `fclose` closes an open stream. (Is this necessary? Should we maybe close as soon as stream handle is popped from stack?)
- `fgetc` gets a single character from the stream. This is either an integer withe labeltype `Integer` or it is a `0` with labeltype `EOF` if the end of the file was reached.
- `fputc` puts a single character (byte) to the stream.
- `fseek` moves the file position indicator to a specific point (in bytes) in the file.
- `ftell` gets the current file position (in bytes).

- `stdin` puts the STDIN stream handle on top of the stack.
- `stdout` puts the STDOUT stream handle on top of the stack.
- `stderr` puts the STDERR stream handle on top of the stack. (is this one absolutely necessary?)


TODO: File system names (ls, cd, etc).





#

A Jux Token is either a single identifier, or a pair of two jux tokens.

a 'simple' identifier:
- (identifier, type)
where integers and [],(the empty quotation) are also identifiers.

or:
((a, b), type), where a and b are both a Jux Token. ` (a, b)` might also be written as `[a | b]`.

This second definition lets us create more advanced data structures, such as quotations and trees.
Many definitions abstract the second definition, to make it more fast, saying 'a token is either a single token with a type or a (possibly improper) linked list of tokens with a type'.

Strings are a list of Integers. They are only treated differently from normal quotations during output. (As well as there existing a parser shorthand to create a string by delimiting it with `"..."`)

Depending on the `type` label a structure has, values might be treated differently. This mostly is important when supplying custom implementations for certain kinds of structures. If, for instance, you would like to use native strings