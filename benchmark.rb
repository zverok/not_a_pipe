require 'benchmark/ips'
require 'json'

RANGE = (0..10_000)

# Simple Ruby version
def naive
  RANGE.each do |i|
    i = Math.sqrt(i).round
    t = Time.at(i)
    JSON.generate({hour: t.hour, min: t.min})
  end
end


# .then-based Ruby version

def with_then
  RANGE.each do |i|
    i.then { Math.sqrt(_1) }.round.then { Time.at(_1) }.then { {hour: _1.hour, min: _1.min} }
      .then { JSON.generate(_1) }
  end
end

# not_a_pipe version
require 'not_a_pipe'
extend NotAPipe

not_a_pipe def with_not_a_pipe
  RANGE.each do |i|
    i >> Math.sqrt >> _.round >> Time.at >> {hour: _.hour, min: _.min} >> JSON.generate
  end
end

# https://github.com/LendingHome/pipe_operator
require 'stringio'
require 'pipe_operator'

def with_pipe_operator
  RANGE.each do |i|
    i.pipe do
      Math.sqrt
      round
      Time.at
      # the only way to achieve this with pipe_operator. We also can't use the name `then`, as
      # it would be parsing error
      yield_self { {hour: _1.hour, min: _1.min} }
      JSON.generate
    end
  end
end

# https://github.com/hopsoft/pipe_envy
# The gem doesn't support chaining Proc-s, so instead of using it directly, its code is copied
# and slightly enhanced; the approach stays the same.
module PipeEnvy
  def self.refine_pipe(klass)
    refine klass do
      define_method :| do |arg|
        if arg.is_a?(Array)
          method = arg.shift
          block  = arg.pop if arg.last.is_a?(Proc)
          args   = arg
        end
        method ||= arg
        args   ||= []

        # in pipe_envy, this line was:
        # if method.is_a?(Method)
        if method.respond_to?(:call)
          result = method.call(*([self] + args), &block)
        else
          result = send(method, *args, &block)
        end
        result
      end
    end
  end

  refine_pipe Object
  refine_pipe Array
  refine_pipe Integer
end
using PipeEnvy

def with_pipe_envy
  RANGE.each do |i|
    i | Math.method(:sqrt) | :round | Time.method(:at) | proc { {hour: _1.hour, min: _1.min} } |
      JSON.method(:generate)
  end
end

Benchmark.ips do |x|
  x.report('naive') { naive }
  x.report('.then') { with_then }
  x.report('not_a_pipe') { with_not_a_pipe }
  x.report('pipe_operator') { with_pipe_operator }
  x.report('pipe_envy') { with_pipe_envy }
  x.compare!
end
