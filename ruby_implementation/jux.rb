require_relative 'jux/helper'
require_relative 'jux/token'
require_relative 'jux/parser'
require_relative 'jux/evaluator'
require_relative 'jux/primitive'
require_relative 'jux/identifier'
require_relative 'jux/escaped_identifier'

module Jux

end

def j(str)
	fq = Jux::Parser.parse(str)
	Jux::Evaluator.evaluate(fq)	
end
