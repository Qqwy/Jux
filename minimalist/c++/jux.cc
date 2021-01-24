#include <iostream>

int memory[20000] = {0, 0, 0, 0, 0, 0, 64};
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

// lodsl-like implementation
void run_instruction(core_instruction instruction) {
  switch(instruction) {
  case compileme:
    {
      push_dict(*pc);
    }
    break;
  case runme:
    {
      push_call(*pc);
      pc = &memory[*pc];
    }
    break;
  case pushint:
    {
      ++pc;
      int val = memory[*pc];
      push_value(val);
    }
    break;
  case compile_word:
    break;
  case define:
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
    break;
  case returntocaller:
    *pc = pop_call();
    break;
  }

  ++pc;
}

int main() {
  
}
