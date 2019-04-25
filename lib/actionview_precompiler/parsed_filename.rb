module ActionviewPrecompiler
  class ParsedFilename
    attr_reader :path, :action, :prefix, :options, :details

    def initialize(path)
      @path = path

      details = parse_template_path(path)
      @prefix = details.delete(:prefix)
      @action = details.delete(:action)
      @partial = details.delete(:partial)
      @details = details
    end

    def partial?
      @partial
    end

    def path_regex
      handlers = ActionView::Template::Handlers.extensions.map { |x| Regexp.escape(x) }.join("|")
      formats = ActionView::Template::Types.symbols.map { |x| Regexp.escape(x) }.join("|")
      locales = "[a-z]{2}(?:-[A-Z]{2})?"
      variants = "[^.]*"
      %r{
        \A
        (?:(?<prefix>.*)/)?
        (?<partial>_)?
        (?<action>.*?)
        (?:\.(?<locale>#{locales}))??
        (?:\.(?<format>#{formats}))??
        (?:\+(?<variant>#{variants}))??
        (?:\.(?<handler>#{handlers}))?
        \z
      }x
    end

    def parse_template_path(path)
      match = path_regex.match(path)

      {
        prefix: match[:prefix] || "",
        action: match[:action],
        partial: !!match[:partial],
        locale: match[:locale]&.to_sym,
        handler: match[:handler]&.to_sym,
        format: match[:format]&.to_sym,
        variant: match[:variant]
      }
    end
  end
end
