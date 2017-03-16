module Jux
  class Primitive
    class << self
      def dup(stack, _known_definitions)
        top = stack.pop
        stack.push(Jux::Helper.deep_dup(top))
        stack.push(Jux::Helper.deep_dup(top))
        stack
      end

      def swap(stack, _known_definitions)
        top = stack.pop
        second = stack.pop
        stack.push(top)
        stack.push(second)
        stack
      end

      def pop(stack, _known_definitions)
        stack.pop
        stack
      end

      def dip(stack, known_definitions)
        quot = stack.pop
        top = stack.pop
        puts "Dip: `#{quot.val.inspect}` on `#{stack.inspect}`"
        stack, _kd = Jux::Evaluator.evaluate_on(quot.val, stack, known_definitions)
        stack.push(top)
        stack
      end

      def add(stack, _known_definitions)
        b = stack.pop
        a = stack.pop
        stack.push(Jux::Token.new(a.val + b.val, a.type))
        stack
      end

      def sub(stack, _known_definitions)
        b = stack.pop
        a = stack.pop
        stack.push(Jux::Token.new(a.val - b.val, a.type))
        stack
      end

      def nand(stack, _known_definitions)
        b = stack.pop
        a = stack.pop
        if b.val == false && a.val == false
          stack.push(true)
        else
          stack.push(false)
        end
        stack
      end

      def cons(stack, _known_definitions)
        head = stack.pop
        tail = stack.pop
        tail.val.push(head)
        stack.push(tail)
        stack
      end

      def uncons(stack, _known_definitions)
        quot = stack.pop
        head = quot.val.pop
        stack.push(Jux::Helper.deep_dup(quot))
        stack.push(head)
        stack
      end

      def redef(stack, known_definitions)
        implementation = stack.pop
        _documentation = stack.pop
        fun_name = stack.pop
        known_definitions[fun_name.val.name] = implementation.val # Note the mutability of known_definitions
        stack
      end

      def def(stack, known_definitions)
        implementation = stack.pop
        _documentation = stack.pop
        fun_name = stack.pop
        puts "Defining #{fun_name} as `#{implementation}`"
        raise "Attempted to define already existing function `#{fun_name.val}`" unless known_definitions[fun_name.val.name].nil?
        known_definitions[fun_name.val.name] = implementation.val # Note the mutability of known_definitions
        stack
      end

      # TODO: Tail-recursive
      def ifte(stack, known_definitions)
        else_quot = stack.pop
        then_quot = stack.pop
        condition_quot = stack.pop
        #condition_stack = Jux::Helper.deep_dup(stack)
        stack, kd2 = Jux::Evaluator.evaluate_on(condition_quot.val, stack, known_definitions)
        
        # TODO: Definitions inside ifte
        if stack.pop != Jux::Token.new(false, 'Boolean')
          stack, kd3 = Jux::Evaluator.evaluate_on(then_quot.val, stack, kd2)
        else
          stack, kd3 = Jux::Evaluator.evaluate_on(else_quot.val, stack, kd2)
        end
        stack
      end

      def eq?(stack, _known_definitions)
        b = stack[-1]
        a = stack[-2]
        puts "Comparing: #{a.inspect} with #{b.inspect}"
        stack.push Jux::Token.new(a.val == b.val, 'Boolean')
      end

      def compare(stack, _known_definitions)
        b = stack[-1]
        a = stack[-2]
        stack.push(Jux::Token.new(a <=> b, "Integer"))
      end

      def bnot(stack, _known_definitions)
        top = stack.pop
        top = ~top
        stack.push top
      end

      def band(stack, _known_definitions)
        b = stack.pop
        a = stack.pop
        stack.push(a & b)
      end

      def bor(stack, _known_definitions)
        b = stack.pop
        a = stack.pop
        stack.push(a | b)
      end

      def bxor(stack, _known_definitions)
        b = stack.pop
        a = stack.pop
        stack.push(a ^ b)
      end

      def to_string(stack, _known_definitions)
      	top = stack.pop
      	stack.push Jux::Helper.ruby_str_to_jux_str(top.to_s)
      end

      def to_identifier(stack, _known_definitions)
      	top = stack.pop
      	str = Jux::Helper.jux_str_to_ruby_str(top)
      	raise "Invalid identifier `#{str}`" unless Jux::Parser.valid_identifier?(str)
      	stack.push Jux::Identifier.new(str)
      end

      def type(stack, _known_definitions)
        top = stack[-1]
        puts top.inspect
        stack.push Jux::Token.new(Jux::Identifier.new(top.type),"Identifier")
        stack
      end

      def cast_to(stack, _known_definitions)
        type_identifier = stack.pop
        elem = stack.last
        elem.type = type_identifier.val.name
        stack
      end

      def inspect_stack(stack, _known_definitions)
        puts 'stack: ' + Jux::Helper.stack_to_str(stack)
        stack
      end
    end
  end
end
