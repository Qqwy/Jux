#include <iostream> // std::cin, std::cout
#include <string>  // std::string
#include <vector> // vector
#include <cstring> // memcmp

#include <array> // array

// int memory[20000] = {0, 0, 0, 0, 0, 0, 64};
std::array<int, 20000> memory;
int *pc = &memory[0];
int *t = &memory[1];
int *r = &memory[2];
int *here = &memory[3];
int *h = &memory[4];


enum core_instruction {
  compileme = 0,
  runme,
  pushint,
  compile_word,
  define,
  subtract,
  negative,
  fetch,
  store,
  getcharacter,
  putcharacter,
  immediate,
  returntocaller
};
int const num_core_instructions = 13;

void dump_memory() {
  std::cout << "Memory dump:\n";
  for(size_t index = 0; index < 512; ++index) {
    std::cout << index << ":  " << memory[index] << '\t' << static_cast<char>(memory[index]) << '\n';
  }
}


void push(int * stack_top, int value) {
  memory[*stack_top] = value;
  ++(*stack_top);
}

int pop(int * stack_top) {
  --(*stack_top);
  int val = memory[*stack_top];
  return val;
}

void push_value(int value) {
  push(t, value);
}

int pop_value() {
  return pop(t);
}

void push_call(int address) {
  push(r, address);
}

int pop_call() {
  return pop(r);
}

void push_dict(int value) {
  push(h, value);
}
int pop_dict() {
  return pop(h);
}

std::string read_word() {
  std::string str;
  if(!std::cin) {

    std::cout << "EOF encountered. Good bye!\n";
    exit(0);
  }
  std::cin >> str;
  return str;
}

// because we want to store individual characters in individual memory cells.
// not very memory-efficient, but simple
std::vector<int> wordname_to_wide_wordname(std::string wordname) {
  std::cout << "converting `" << wordname << "` into wide format\n";
  std::vector<int> wide_wordname;
  std::copy(wordname.begin(), wordname.end(), std::back_inserter(wide_wordname));
  return wide_wordname;
}

int lookup_in_dictionary(std::vector<int> wide_wordname) {
  const int *wide_wordname_ptr = wide_wordname.data();
  int length = wide_wordname.size();

  int dictionary_entry = memory[*here];
  while (true) {
    std::cout << "Comparing against dictionary entry " << dictionary_entry << '\n';

    if(dictionary_entry == 0) {
      return 0;
    }
    int prev = memory[dictionary_entry];
    int entry_name_length = memory[dictionary_entry + 1];
    int *entry_name_ptr = &memory[dictionary_entry + 2];

    if(length == entry_name_length && memcmp(wide_wordname_ptr, entry_name_ptr, length) == 0) {
      std::cout << "success\n";
      return dictionary_entry;
    }

    dictionary_entry = prev;
  }
}

int dictionary_entry_to_codeword_location(int dictionary_entry) {
  int entry_name_length = memory[dictionary_entry + 1];
  int codeword_location = dictionary_entry + 2 + entry_name_length;
  return codeword_location;
}


// lodsl-like implementation
void run_instruction(core_instruction instruction) {
  switch(instruction) {
  case compileme:
    {
      std::cout << "running compileme\n";
      push_dict(*pc);
    }
    break;
  case runme:
    {
      std::cout << "running runme\n";
      push_call(*pc);
      pc = &memory[*pc + 1];
    }
    break;
  case pushint:
    {
      std::cout << "running pushint\n";
      ++(*pc);
      int val = memory[*pc];
      push_value(val);
    }
    break;
  case compile_word:
    {
      std::cout << "Lookup in compile_word\n";
      std::string wordname = read_word();
      int dictionary_address = lookup_in_dictionary(wordname_to_wide_wordname(wordname));
      if(dictionary_address != 0) {
        int codeword_location = dictionary_entry_to_codeword_location(dictionary_address);
        run_instruction(static_cast<core_instruction>(memory[codeword_location]));
      } else {
        try {
          int val = std::stoi(wordname);
          push_dict(pushint);
          push_dict(val);
        } catch (...) {
          dump_memory();

          std::cerr << "error: `" << wordname << "` cannot be found in the dictionary but is also not a number literal. Exiting.\n";
          exit(1);
        }
      }
      std::cout << "end of compile_word\n";
    }
    break;
  case define:
    {
      std::cout << "Lookup in define\n";
      std::vector<int> wide_wordname = wordname_to_wide_wordname(read_word());
      push_dict(*here); // link to previous dictionary entry
      *here = *h - 1; // update most recent entry pointer to point to current dictionary entry (which starts with the link to the previous entry, hence the - 1)
      push_dict(wide_wordname.size());
      for(auto character : wide_wordname) {
        push_dict(character);
      }
      push_dict(compileme);
        std::cout << "end of define\n";
    }
    break;
  case subtract:
    {
      int rhs = pop_value();
      int lhs = pop_value();
      int result = lhs - rhs;
      push_value(result);
    }
    break;
  case negative:
    {
      int val = pop_value();
      int result = val < 0;
      push_value(result);
    }
    break;
  case fetch:
    {
      int memory_ptr = pop_value();
      int val = memory[memory_ptr];
      push_value(val);
    }
    break;
  case store:
    {
      int memory_ptr = pop_value();
      int val = pop_value();
      memory[memory_ptr] = val;
    }
    break;
  case getcharacter:
    {
      int val = getchar();
      push_value(val);
    }
    break;
  case putcharacter:
    {
      int val = pop_value();
      putchar(val);
    }
    break;
  case immediate:
    {
      std::cout << "running immediate\n";
      pop_dict();
      push_dict(runme);
    }
    break;
  case returntocaller:
    {
      std::cout << "running return\n";
      *pc = pop_call();
    }
    break;
  }
}


void define_core_instruction(core_instruction instruction) {
  run_instruction(define);

  // put the instruction in the codeword section of the dictionary entry

  if(instruction == define || instruction == immediate){
    run_instruction(immediate);
    // pop_dict();
  }
  push_dict(instruction);
}

int main() {
  // initialize machine
  // initialize stack pointers
  *r = 8; // start of call stack is after special-value region. It is 1024 words large. Stackoverflow is not detected.
  *h = *r + 128; // start of dictionary is after call stack region.
  *t = 10000; // start of value stack is halfway through memory.

  // set up core instructions in dictionary
  for(size_t index = 0; index < num_core_instructions; ++ index) {
    define_core_instruction(static_cast<core_instruction>(index));
  }

  // define first version of internal interpreter:
  // compile a word and then call itself (i.e. forever repeating this procedure)
  run_instruction(define);
  run_instruction(immediate);
  int myself = *h - 1;
  push_dict(dictionary_entry_to_codeword_location(lookup_in_dictionary(wordname_to_wide_wordname("compile_word"))));
  // push_dict(compile_word);
  push_dict(myself);

  *pc = myself;



  dump_memory();
  size_t no_instruction = 0;
      // start program execution proper
  while(true) {
    ++no_instruction;
    if(no_instruction > 100) {
      break;
    }

    std::cout << no_instruction << " pc: " << *pc << '\n';
    std::cout << no_instruction << " memory[pc]: "<< memory[*pc] << '\n';
    core_instruction instruction = static_cast<core_instruction>(memory[*pc]);
    run_instruction(instruction);
    *pc = pop_call();
    (++*pc);
    *pc = memory[*pc];
  }

  dump_memory();

}
