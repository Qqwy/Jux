module Jux
	class Token
		attr_accessor :val, :type
		def initialize(val, type)
			@val  = val
			@type = type
		end

		def to_s
			"#{self.val}"
		end
		def inspect
			"#{self.val}(#{self.type})"
		end
	end
end
