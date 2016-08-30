module Jux
  class Helper
    class << self
      def ruby_str_to_jux_str(str)
        quotation =
          str
          .unpack('c*')
          .map { |x| Jux::Token.new(x, "Integer")}
        Jux::Token.new(quotation, "String")
      end

      def jux_str_to_ruby_str(token)
        quotation = token.val
        quotation.map(&:val)
                 .pack('c*')
      end

      def stack_to_str(stack, show_types = false)
        if show_types
          stack.map(&:inspect).join(' ')
        else 
          stack.map(&:to_s).join(' ')
        end
      end
    end
  end
end
