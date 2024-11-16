require 'parser/current'
require 'unparser'
require 'method_source'

module NotAPipe
  # Usage:
  #
  #   not_a_pipe def my_method
  #      value >> Some.method >> _.some_call >> [_, anything]
  #   end
  #
  # Will rewrite and reevaluate method code, replacing it with code like:
  #
  #   def my_method
  #      _ = value
  #      _ = Some.method(_)
  #      _ = _.some_call
  #      _ = [_, anything]
  #   end
  def not_a_pipe(name)
    meth = is_a?(Module) ? instance_method(name) : method(name)
    # Replacement is because method_source will read `not_a_pipe def foo; ...` from source including
    # not_a_pipe decorator.
    src = meth.source.sub(/not_a_pipe\s*?/, '')
    src = NotAPipe.rewrite(src)

    if is_a?(Module)
      module_eval src
    else
      instance_eval src
    end
  end

  class << self
    def rewrite(code)
      node = Unparser.parse(code)
      node = rewrite_node(node)
      # Without predefined `_` local var, parser will consider it a method. Forcibly replace all `_()` with `_`
      Unparser.unparse(node).gsub(/\b_\(\)/, '_')
    end

    private

    def rewrite_node(node)
      case node
      in [:send, left, :>>, right]
        # foo >> bar >> baz is parsed as:
        #   left = foo >> bar
        #   right = baz
        # `flatten_pipes` will make them into
        #   [foo, bar, baz]
        # `rewrite_step` will substitute `Some.method(some, args)` with `Some.method(_, some, args)`, unless
        # `_` is already a part of the expression
        steps = [*flatten_pipes(left), right].then { |first, *rest| [first, *rest.map { rewrite_step(_1) }] }
        # Now turn every foo, bar, baz into `_ = foo`, `_ = bar`, `_ = baz`
        s(:begin, *steps.map { s(:lvasgn, :_, _1) })
      in Parser::AST::Node
        s(node.type, *node.children.map { rewrite_node(_1) })
      else
        node
      end
    end

    def flatten_pipes(node)
      case node
      in [:send, left, :>>, right]
        [*flatten_pipes(left), right]
      else
        [node]
      end
    end

    def rewrite_step(node)
      return node if node.loc.expression.source.match?(/\b_\b/)

      case node
      in [:send, receiver, sym, *args]
        s(:send, receiver, sym, s(:lvar, :_), *args)
      else
        raise ArgumentError, "Unrewriteable step: #{node}"
      end
    end

    def s(type, *children)
      Parser::AST::Node.new(type, children)
    end
  end
end
