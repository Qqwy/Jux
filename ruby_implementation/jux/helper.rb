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
    end
  end
end
