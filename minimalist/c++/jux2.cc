#include <iostream> // std::cin, std::cout
#include <string>  // std::string
#include <vector> // vector
#include <cstring> // memcmp

#include <array> // array


typedef long word_t;

std::array<word_t, 20000> memory;
word_t &pc = memory[0]; // program counter
word_t &t = memory[1];  // top of value stack
word_t &r = memory[2]; // top of return stack
word_t &latest = memory[3]; // address of beginning of newest dictionary entry
word_t &here = memory[4]; // address of last instruction added to the dictionary



enum core_instruction {
  compileme = 0,
  runme,
  pushint,
  define,
  immediate,
  compile_word,
  returntocaller,
  subtract,
  negative,
  fetch,
  store,
  getcharacter,
  putcharacter
};
word_t const num_core_instructions = 13;

void dump_memory() {
  std::cout << "Memory dump:\n";
  for(size_t index = 0; index < static_cast<size_t>(here); ++index) {
    std::cout << index << ":  " << memory[index] << '\t' << static_cast<char>(memory[index]) << '\n';
  }
}

void push(word_t &stack_top, word_t value) {
  memory[stack_top] = value;
  ++stack_top;
}

word_t pop(word_t &stack_top) {
  --stack_top;
  word_t val = memory[stack_top];
  return val;
}

void push_value(word_t value) {
  push(t, value);
}

word_t pop_value() {
  return pop(t);
}

void push_call(word_t address) {
  push(r, address);
}

word_t pop_call() {
  return pop(r);
}

void push_dict(word_t value) {
  push(here, value);
}

word_t pop_dict() {
  return pop(here);
}

std::string read_word() {
  std::string str;
  std::cin >> str;
  if(str == "") {
    std::cout << "EOF encountered. Good bye!\n";
    exit(0);
  }
  return str;
}

// because we want to store individual characters in individual memory cells.
// not very memory-efficient, but simple
std::vector<word_t> wordname_to_wide_wordname(std::string wordname) {
  std::cout << "converting `" << wordname << "` word_to wide format\n";
  std::vector<word_t> wide_wordname;
  std::copy(wordname.begin(), wordname.end(), std::back_inserter(wide_wordname));
  return wide_wordname;
}

word_t lookup_in_dictionary(std::vector<word_t> wide_wordname) {
  word_t size = wide_wordname.size();
  word_t dictionary_entry = memory[latest];
  while (true) {
    std::cout << "Comparing against dictionary entry " << dictionary_entry << '\n';

    if(dictionary_entry == 0) {
      return 0;
    }
    word_t prev = memory[dictionary_entry];
    word_t entry_name_length = memory[dictionary_entry + 1];
    word_t *entry_name_ptr = &memory[dictionary_entry + 2];

    if(size == entry_name_length && memcmp(wide_wordname.data(), entry_name_ptr, size * sizeof(word_t)) == 0) {
      for(word_t index = 0; index < size; ++index) {
        std::cout << wide_wordname[index]  << " vs. " << entry_name_ptr[index] << '\n';
      }
      std::cout << "success\n";
      return dictionary_entry;
    }

    dictionary_entry = prev;
  }
}


word_t lookup_in_dictionary(std::string wordname) {
  return lookup_in_dictionary(wordname_to_wide_wordname(wordname));
}

word_t dictionary_entry_to_codeword_location(word_t dictionary_entry) {
  word_t entry_name_length = memory[dictionary_entry + 1];
  word_t codeword_offset = 2 + entry_name_length;
  return dictionary_entry + codeword_offset;
}


void run_instruction(word_t instruction_address);
void run_compile_word() {
  std::cout << "compile_word\n";

    std::string wordname = read_word();
    int dictionary_address = lookup_in_dictionary(wordname);
    if(dictionary_address != 0) {
      int codeword_location = dictionary_entry_to_codeword_location(dictionary_address);
      run_instruction(codeword_location);
    } else {
      try {
        int val = std::stoi(wordname);
        push_dict(dictionary_entry_to_codeword_location(lookup_in_dictionary("pushint")) + 1);
        push_dict(val);
      } catch (...) {
        dump_memory();

        std::cerr << "error: `" << wordname << "` cannot be found in the dictionary but is also not a number literal. Exiting.\n";
        exit(1);
      }
    }
    std::cout << "end of compile_word\n";
}

void run_define() {
  std::cout << "define\n";
  std::vector<word_t> wide_wordname = wordname_to_wide_wordname(read_word());
  push_dict(latest); // link to previous dictionary entry
  latest = here - 1; // update most recent entry pointer to point to current dictionary entry (which starts with the link to the previous entry, hence the - 1)
  push_dict(wide_wordname.size());
  for(auto character : wide_wordname) {
    push_dict(character);
  }
  push_dict(compileme);
  std::cout << "end of define\n";
}

void run_immediate() {
  std::cout << "immediate\n";
  pop_dict();
  push_dict(runme);
}

void run_instruction(word_t instruction_address) {
  core_instruction instruction = static_cast<core_instruction>(memory[instruction_address]);
  std::cout << "instruction: " << instruction << "\t";
  switch(instruction) {
  case compileme: // TODO doubt
    {
      std::cout << "compileme\n";
      push_dict(instruction_address + 1);
    }
    break;
  case runme: // TODO doubt
    {
      std::cout << "runme\n";
      push_call(pc); // store 'next instruction to be run' on callstack
      pc = instruction_address + 1; // and replace it for now with the instruction following this one.
    }
    break;
  case pushint:
    {
      // the pc points not to an instruction but to the numeric value to push,
      // so push it and skip it.
      std::cout << "pushint\n";
      int val = memory[pc];
      ++pc;
      push_value(val);
    }
  case compile_word:
    run_compile_word();
    break;
  case define:
    run_define();
    break;
  case immediate:
    run_immediate();
    break;
  case returntocaller:
    {
      std::cout << "return\n";
      pc = pop_call();
    }
    break;
  case subtract:
    {
      std::cout << "subtract\n";
      int rhs = pop_value();
      int lhs = pop_value();
      int result = lhs - rhs;
      push_value(result);
    }
    break;
  case negative:
    {
      std::cout << "negative\n";
      int val = pop_value();
      int result = val < 0;
      push_value(result);
    }
    break;
  case fetch:
    {
      std::cout << "fetch\n";
      int memory_ptr = pop_value();
      int val = memory[memory_ptr];
      push_value(val);
    }
    break;
  case store:
    {
      std::cout << "store\n";
      int memory_ptr = pop_value();
      int val = pop_value();
      memory[memory_ptr] = val;
    }
    break;
  case getcharacter:
    {
      std::cout << "getchar\n";
      int val = getchar();
      push_value(val);
    }
    break;
  case putcharacter:
    {
      std::cout << "putchar\n";
      int val = pop_value();
      putchar(val);
    }
    break;
  }
}

void run_instructions() {
  size_t count = 0;
  while(true) {
    std::cout << count << ": ";

    // core_instruction instruction_address = static_cast<core_instruction>(memory[pc]);
    word_t instruction_address(memory[pc]);
    ++pc;

    std::cout << "\t pc: " << pc << "\t m[pc-1]: " << instruction_address << "\t";

    // during `run_instruction`, `pc` will always point to the address of the next codeword to be run.
    run_instruction(instruction_address);

    ++count;
    if(count > 100) {
      break;
    }
  }
}

void initialize_dictionary() {
  for(word_t instruction = 0; instruction < num_core_instructions; ++instruction) {
    run_define();
    if(instruction == define || instruction == immediate){
      // run_immediate();
      pop_dict();
    }
    push_dict(instruction);
    push_dict(returntocaller);
  }
  // for(word_t instruction = 5; instruction < num_core_instructions; ++instruction) {
  //   run_define();
  //   push_dict(instruction);
  //   push_dict(returntocaller);
  // }
}

void initialize_inner_interpreter() {
  run_define();
  run_immediate();
  int inner_interpreter_start = here - 1;
  push_dict(dictionary_entry_to_codeword_location(lookup_in_dictionary("compile_word")) + 1);
  push_dict(inner_interpreter_start);

  pc = inner_interpreter_start + 1;
}

int main() {
  r = 8;
  latest = 0;
  here = r + 128;
  t = 10000;

  initialize_dictionary();
  initialize_inner_interpreter();
  dump_memory();

  run_instructions();
  dump_memory();
}