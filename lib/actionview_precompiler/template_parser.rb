require "action_view"
require "parser/current"

module ActionviewPrecompiler
  class TemplateParser
    attr_reader :filename, :basename, :handler

    class FakeTemplate
      def type
        nil
      end
    end

    def initialize(filename)
      @filename = filename
      @basename = File.basename(filename)
      handler_ext = @basename.split(".").last
      @handler = ActionView::Template.handler_for_extension(handler_ext)
      @is_partial = !!@basename.start_with?("_")
    end

    def partial?
      @is_partial
    end

    def render_calls
      RenderParser.new(parsed).render_calls
    end

    def parsed
      @parsed ||= Parser::CurrentRuby.parse(compiled_source)
    end

    def compiled_source
      @handler.call(FakeTemplate.new, File.read(@filename))
    end
  end
end
