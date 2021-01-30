# the compiler: gcc for C program, define as g++ for C++
  CC = g++

  # compiler flags:
  #  -g     - this flag adds debugging information to the executable file
  #  -Wall  - this flag is used to turn on most compiler warnings
  #  -Werror  - stop compilation on warnings
  #  -std=c++2a - use the most recent C++ standard/features.
  CFLAGS  = -g -Wall -Werror --std=c++2a

  # The build target
  TARGET = jux

  all: $(TARGET)

  $(TARGET): $(TARGET).cc
		$(CC) $(CFLAGS) -o $(TARGET) $(TARGET).cc

  run: all
		cat ../example_programs/prelude2.jux | ./$(TARGET)

  clean:
		$(RM) $(TARGET)
