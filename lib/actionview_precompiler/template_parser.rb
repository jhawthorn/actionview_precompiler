require "action_view"

module ActionviewPrecompiler
  class TemplateParser
    attr_reader :filename, :basename, :handler

    class FakeTemplate
      def identifier
        "fake_template"
      end

      def type
        nil
      end

      def format
        nil
      end
    end

    def initialize(filename)
      @filename = filename
      @basename = File.basename(filename)
      handler_ext = @basename.split(".").last
      @handler = HANDLERS_FOR_EXTENSION[handler_ext]
      @is_partial = !!@basename.start_with?("_")
    end

    def partial?
      @is_partial
    end

    def render_calls
      src = File.read(@filename)
      if src.include?("render")
        compiled_source = @handler.call(FakeTemplate.new, File.read(@filename))
        RenderParser.new(compiled_source).render_calls
      else
        []
      end
    end
  end
end
