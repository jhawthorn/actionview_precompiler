module ActionviewPrecompiler
  class ControllerParser
    def initialize(filename)
      @filename = filename
    end

    def render_calls
      src = File.read(@filename)
      RenderParser.new(src, from_controller: true).render_calls
    end
  end
end
