This is the main repository/project folder of Jux.

Jux is a simple *stack-based concatenative functional* programming language.
Jux has two intertwined goals:

- Be a very simple basic language that is as easy as possible to implement on any target platform.
- Be an easy target for other languages to compile to, not sacrificing features along the way.


To be able to live up to both of these goals, Jux defines a very small set of literals and functions that *have* to be defined by an implementation, but has a much larger standard library with 'fallback' implementations that are used by default. Target implementations can be made more efficient by building native versions of more and more of these standard library functions.

The same holds true for data types: The literal data types a target *has* to implement are `int`, `string`, `quotation`(linked lists), `symbol`(a name with a constant integer value). The other supported data types (`tuple`(pairs, triples, etc; fixed-size arrays of values), `dict`(an associative key->value store ) and `tree` are by default implemented on top of lists.)


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
- TODO `y`: Useful to make recursive definitions.

### Comparisons

- `compare`: Pops the top two items, `a` and `b` (`a` being the item originally on top). Puts `-1` on top of the stack if `b` is smaller than `a`, `0` if they are equal, and `1` if `a` is larger than `b`.

Note that _all_ Jux values are comparable with each other; They form a monoid. This is useful to easily create sorting functions and associative lookups without extra overhead or edge cases.

Comparisons have the following order:
`Integer/Float < Function < String < Quotation`
- An Integer/Float is compared by its numerical value
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
- `mul`
- `pow`
- `div`
- `gcd`
- `lcm`
- `fact`
- `fib`
- `isqrt`

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
- `bcomplement`: Pops top of the stack. Pushes the bitwise complement of that Integer.
- `bor`: Pops the top two elements `a` and `b` (`a` being the item originally on top). Pushes the bitwise or of these two Integers. 
- `band`: Pops the top two elements `a` and `b` (`a` being the item originally on top). Pushes the bitwise and of these two Integers.

The standard library extends on this with:
- `bxor`: Pops the top two elements `a` and `b` (`a` being the item originally on top). Pushes the bitwise xor of these two Integers.


### Quotation/List operations

- `cons`: Pops the top of the stack `a` and the quotation `q` just below it, and returns a new quotation `q2` where `a` is the final item in `q`.
- `uncons`: Pops the top of the stack `q2`, and extracts the final item `a`. Pushes `q` which is `q2` without this item. Then pushes `a`.
- `reduce`: Given a quotation `q`, a starting accumulator `acc`, and a quotation-list `l` to perform on:
  - Pushes `acc`.
  - Pushes the first value in `l`
  - Evaluates `q`
  - Pushes the next value in `l`.
  - Evaluates `q`
  - etc, until the list is empty.

The standard library extends on this with:
- `concat`: Concatenates two quotations into one.
- `length`: Returns the number of items in a quotation.
- `map`: Maps a quotation `q` over each of the elements in the list `l`, returning a new list.
- `sum`: Calculates the arithmetic sum of a list of integers.
- `product`: Calculates the arithmetic product of a list of integers.

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




# Future Goals

- Create a way to use rewrite rules to enhance efficiency; things like `reverse length === length`
- Self-hosting
- Multiple implementations.
- Explore the advantages/drawbacks of a bytecode variant of Jux.
- Explore (dependently?) statical typing and if/how it might work with a concatenative language.


