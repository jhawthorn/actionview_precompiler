require "parser/current"

module ActionviewPrecompiler
  class RenderParser
    def initialize(code)
      @code = code
      @code = Parser::CurrentRuby.parse(code) if code.is_a?(String)
    end

    def render_calls
      []
    end
  end
end
