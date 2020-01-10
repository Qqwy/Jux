#require 'deep_dup'

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
  res_stack, kd = Jux::Evaluator.evaluate(fq)
  puts Jux::Helper.stack_to_str(res_stack)
  [res_stack, kd]
end

def jt(str)
  fq = Jux::Parser.parse(str)
  res_stack, kd = Jux::Evaluator.evaluate(fq)
  puts Jux::Helper.stack_to_str(res_stack, true)
  [res_stack, kd]
end
