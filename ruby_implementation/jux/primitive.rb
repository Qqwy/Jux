module Jux
	class Primitive
		class << self
			def dup(stack)
				top = stack[-1]
				stack.push(top)
				stack
			end

			def swap(stack)
				top = stack.pop
				second = stack.pop
				stack.push(top)
				stack.push(second)
				stack
			end

			def pop(stack)
				stack.pop
				stack
			end

			def dip(stack)
				quot = stack.pop.val
				top = stack.pop
				stack, _kd = Jux::Evaluator.evaluate_on(quot, stack, {})
				stack.push(top)
				stack
			end


			def add(stack)
				b = stack.pop
				a = stack.pop
				stack.push(Jux::Token.new(a.val + b.val, a.type))
				stack
			end

			def sub(stack)
				b = stack.pop
				a = stack.pop
				stack.push(Jux::Token.new(a.val - b.val, a.type))
				stack
			end

			def nand(stack)
				b = stack.pop
				a = stack.pop
				if b.val == false && a.val == false
					stack.push(true)
				else
					stack.push(false)
				end
				stack
			end

			def cons(stack)
				head = stack.pop
				tail = stack.pop
				tail.val.push(head)
				stack.push(tail)
				stack
			end

			def uncons(stack)
				quot = stack.pop
				head = quot.val.pop
				stack.push(quot)
				stack.push(head)
				stack
			end
		end
	end
end
