require "action_view"

module ActionviewPrecompiler
  class TemplateParser
    include ASTParser

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
      RenderParser.new(parsed).render_calls
    end

    def parsed
      @parsed ||= parse(compiled_source)
    end

    def compiled_source
      @handler.call(FakeTemplate.new, File.read(@filename))
    end
  end
end
