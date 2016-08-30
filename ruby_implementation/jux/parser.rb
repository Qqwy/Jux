module Jux
  class Parser
    class << self
      def whitespace_regexp
        %r{\A\s+}m
      end

      def comment_regexp
        %r{\A#.*}
      end

      def float_regexp
        %r{\A[+-]?\d+\.\d+}
      end

      def integer_regexp
        %r{\A[+-]?\d+}
      end

      def identifier_regexp
        %r{\A[a-zA-Z_][\w.]*[?!]?}
      end

      def escaped_identifier_regexp
        %r{\A/[a-zA-Z_][\w.]*[?!]?}
      end

      def parse(str)
        token_str = str
        function_queue = []

        loop do
          case
          when whitespace_str = token_str.match(whitespace_regexp)
            token_str = token_str[whitespace_str.length..-1]
          when comment_str = token_str.match(comment_regexp)
            token_str = token_str[comment_str.to_s.length..-1]
          when token_str.match(/^\[/)
            quotation, token_str = parse_quotation(token_str)
            function_queue << Jux::Token.new(quotation, "Quotation")
          when token_str.match(/^"/)
            str, token_str = parse_string(token_str)
            function_queue << str
          when escaped_identifier_str = token_str.match(escaped_identifier_regexp)
            function_queue << Jux::Token.new(Jux::EscapedIdentifier.new(escaped_identifier_str.to_s[1..-1]), "Identifier")
          	puts "EscapedIdentifier #{escaped_identifier_str}; Left token str: #{token_str.inspect}"
            token_str = token_str[escaped_identifier_str.to_s.length..-1]
          when identifier_str = token_str.match(identifier_regexp)
            function_queue << Jux::Token.new(Jux::Identifier.new(identifier_str.to_s), "Identifier")
          	puts "Identifier #{identifier_str}; Left token str: #{token_str.inspect}"
            token_str = token_str[identifier_str.to_s.length..-1]
          when integer_str = token_str.match(integer_regexp)
            integer = integer_str[0].to_i
            function_queue << Jux::Token.new(integer, "Integer")
            token_str = token_str[integer_str.to_s.length..-1]
          when token_str == ""
            break
          else
            raise "Improper Jux syntax: `#{token_str}`"
          end
        end
        puts Jux::Helper.stack_to_str(function_queue)  
        function_queue
      end

      def parse_string(token_str)
        i = 1
        loop do
          raise "unmatched \"" if token_str[i].nil?
          break if token_str[i] == '"'
          i+= 1 if token_str[i..(i+1)] == '\"'
          i+= 1
        end
        new_str = Jux::Helper.ruby_str_to_jux_str(token_str[1...i])
        token_str = token_str[(i+1)..-1]
        [new_str, token_str]
      end

      def parse_quotation(token_str)
        i = 0
        depth = 0
        loop do
          raise "unmatched [" if token_str[i].nil?
          if token_str[i] == "["
            depth += 1
          elsif token_str[i] == "]"
            break if depth == 1
            depth -= 1
          end
          i += 1
        end

        quotation = parse(token_str[1...i])
        token_str = token_str[(i+1)..-1]
        [quotation, token_str]
      end

      def valid_identifier?(str)
        str =~ %r{^[a-zA-Z_][\w.]*[?!]?$}
      end
    end
  end
end
