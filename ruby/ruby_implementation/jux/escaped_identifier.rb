module Jux
	class EscapedIdentifier
	  attr_accessor :name
	  def initialize(str)
	    self.name = str
	  end

		def inspect
			"/#{@name}"
		end

		def to_s
			"/#{@name}"
		end
	end

end
