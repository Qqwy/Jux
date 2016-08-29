module Jux
  class Parser
    class << self
      def whitespace_regexp         
        %r{\A\s+}m
      end

      def comment_regexp            
        %r{^#.*}
      end

      def float_regexp              
        %r{^[+-]?\d+\.\d+}
      end

      def integer_regexp            
        %r{^[+-]?\d+}
      end

      def identifier_regexp         
        %r{^[a-zA-Z_][\w.]*[?!]?}
      end

      def escaped_identifier_regexp 
        %r{^/[a-zA-Z_][\w.]*[?!]?}
      end




      def parse(str)
        token_str = str
        function_queue = []

        loop do
          puts token_str.inspect
          puts function_queue.inspect
          case
          when whitespace_str = token_str.match(whitespace_regexp)
            puts "Whitespace"
            token_str = token_str[whitespace_str.length..-1]
            #function_queue << 'Whitespace'
          when comment_str = token_str.match(comment_regexp)
            puts "COMMENT"
            token_str = token_str[comment_str.length..-1]
            #function_queue << 'comment'
          when token_str.match(/^\[/)
            #function_queue << 'quotation_start'
            quotation, token_str = parse_quotation(token_str)
            function_queue << quotation
            #token_str = token_str[1..-1]
          when token_str.match(/^"/)
            #function_queue << 'string_start'
            token_str = token_str[1..-1]
            str, token_str = parse_string(token_str)
            function_queue << str # TODO: Change string to charlist format.
          when escaped_identifier_str = token_str.match(escaped_identifier_regexp)
            puts "escaped identifier"
            function_queue << Jux::EscapedIdentifier.new(escaped_identifier_str.to_s[1..-1])
            token_str = token_str[escaped_identifier_str.to_s.length..-1]
          when identifier_str = token_str.match(identifier_regexp)
            puts "identifier"
            function_queue << Jux::Identifier.new(identifier_str.to_s)
            token_str = token_str[identifier_str.to_s.length..-1]
          when integer_str = token_str.match(integer_regexp)
            puts "integer"
            integer = integer_str[0].to_i
            function_queue << integer
            token_str = token_str[integer_str.length..-1]
          when token_str == ""
            puts "empty"
            puts "BOOM "
            break
          else
            function_queue << 'unknown'
            puts "unknown"
            token_str = token_str[1..-1]
          end
        end
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
        new_str = token_str[1...i]
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
    end
  end
end
