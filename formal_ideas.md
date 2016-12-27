# Introduction

This is a sort of formal specification for Jux, to be used to actually create compilers and interpreters
for it later.

# General



# Compiler parts

## Lexical Analysis

Jux has a very simple syntax. Tokenizing also is very straightforward:

- EOL comments start with `#`
- Multiline comments are delimited with  `(*` and `*)`. Multiline comments _cannot_ be nested. (TODO: Good choice?)
- Strings are delimited with `"`. `\"` can be used to escape a double quote.
- All other kinds of tokens are 'words'.
- Words are separated with one or multiple whitespaces.
- `[` is always a word on its own. `]` is always a word on its own (regardless of whitespace).
- Words are case-sensitive.
- A word that starts with `\`, such as `\foo` is called an 'atom'.


## Syntactical Analysis

## Semantic Analysis

## Code Generation

A special word, `def`, reads three arguments from the stack:
- the name of the to-be-defined word, as atom.
- A documentation string.
- A quotation which is the function body/implementation.

The current function dictionary is then taken and updated with the new function on top.
The function dictionary field should contain:
1) the function name (as key)
2) the function's body, where for each of the contained words, their implementation has been looked up in the function dictionary (before this new word was added).
  - For quotations, this happens as well for the contained elements; each element of the quotation being a `(word, implementation)` tuple.


The Jux program should have a method called `main`, which is the starting point of the program.


TODO: Modules.

## Runtime Environment


