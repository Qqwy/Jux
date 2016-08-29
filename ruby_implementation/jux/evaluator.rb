module Jux
  class Evaluator
    class << self
      def evaluate(function_queue)
        known_definitions = {}
        evaluate_on(function_queue, [], {})
      end

      def evaluate_on(function_queue, stack, known_definitions)
      	# TODO: Deep copy

        until function_queue.empty?
          token = function_queue.shift
          puts token.inspect
          case token.val
          when Integer
            stack << token
          when Array
            stack << token
          when Jux::EscapedIdentifier
            stack << Jux::Token.new(Jux::Identifier.new(token.val.name), token.type)
          when Jux::Identifier
            if Jux::Primitive.respond_to?(token.val.name)
              stack = Jux::Primitive.method(token.val.name).call(stack)
              # TODO: def, redef
            elsif !known_definitions[token.val.name].nil?
              function_queue = known_definitions[token.val.name] + function_queue
            else
              raise "Undefined identifier `#{token.val.name}`"
            end
          end
        end
        [stack, known_definitions]
      end
    end
  end
end
