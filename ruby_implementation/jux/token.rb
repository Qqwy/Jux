module Jux
  class Token
    attr_accessor :val, :type
    def initialize(val, type)
      @val  = val
      @type = type
    end

    def ==(b)
      self.val == b.val && self.type == b.type
    end

    def <=>(b)
      self.val <=> b.val
    end

    def to_s
      if self.val.is_a?(Array)
        if self.type == "String"
          str = Jux::Helper.jux_str_to_ruby_str(self)
          "\"#{str}\""
        else
          arr = self.val.map(&:to_s)
          "[#{arr.join(' ')}]"
        end
      else
      self.val.to_s
      end
    end
    def inspect
    	if  self.type == "String"
    	  str = Jux::Helper.jux_str_to_ruby_str(self)
        "\"#{str}\"(String)"
     	else
	      "#{self.val.inspect}(#{self.type})"
  		end
    end

    def to_ary
      [self]
    end

    # Used by methods like +, -, etc.
    def coerce(other_numeric)
      puts other_numeric.inspect
      if other_numeric.kind_of? Jux::Token
        [other_numeric, self]
      else
        [Jux::Token.new(other_numeric, self.type), self]
      end
    end

    def +(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val += other.val
      res
    end

    def -(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val -= other.val
      res
    end

    def *(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val *= other.val
      res
    end

    def /(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val /= other.val
      res
    end

    def **(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val **= other.val
      res
    end

    def |(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val |= other.val
      res
    end

    def ^(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val ^= other.val
      res
    end

    def &(other)
      other = coerce(other) unless other.is_a? Jux::Token
      res = DeepDup.deep_dup(self)
      res.val &= other.val
      res
    end

    def <=>(other)
      av = self.val
      bv = other.val

      result =
        case
        # Num vs Num
        when av.is_a?(Numeric) && bv.is_a?(Numeric)
          return (av <=> bv)
        # Num vs non-Num
        when av.is_a?(Numeric)
          -1
        when bv.is_a?(Numeric)
          1
        # Bool vs Bool
        when av == true && bv == true
          0
        when av == false && bv == true
          -1
        when av == true && bv == false
          1
        # Bool vs non-Bool
        when av.is_a?(TrueClass) || av.is_a?(FalseClass)
          -1
        when bv.is_a?(TrueClass) || bv.is_a?(FalseClass)
          1
        # Identifier vs Identifier
        when av.is_a?(Jux::Identifier) && bv.is_a?(Jux::Identifier)
          av.name <=> bv.name
        # Identifier vs non-Identifier
        when av.is_a?(Jux::Identifier)
          -1
        when bv.is_a?(Jux::Identifier)
          1
        # EscapedIdentifier vs EscapedIdentifier
        when av.is_a?(Jux::EscapedIdentifier) && bv.is_a?(Jux::EscapedIdentifier)
          av.name <=> bv.name
        # EscapedIdentifier vs non-EscapedIdentifier
        when av.is_a?(Jux::EscapedIdentifier)
          -1
        when bv.is_a?(Jux::EscapedIdentifier)
          1
        # Quotation vs Quotation
        when av.is_a?(Array) && bv.is_a?(Array)
          av <=> bv
        else
          raise "Cannot compare #{av.inspect} <=> #{bv.inspect}"
        end
      Jux::Token.new(result, 'Integer')
    end

    def method_missing(m, *args, &block)
      result = self.val.method(m).call(*args, &block)
      puts result.inspect
      self.val = result
      self
    end

    def respond_to?(m, *args)
      super(m, *args) || self.val.respond_to?(m, *args)
    end
  end
end
