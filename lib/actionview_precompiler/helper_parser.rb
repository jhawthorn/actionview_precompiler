module ActionviewPrecompiler
  class HelperParser
    def initialize(filename)
      @filename = filename
    end

    def render_calls
      src = File.read(@filename)
      return [] unless src.include?("render")
      RenderParser.new(@filename, src).render_calls
    end
  end
end
