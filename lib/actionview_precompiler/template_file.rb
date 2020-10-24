module ActionviewPrecompiler
  class TemplateFile
    attr_reader :fullpath, :relative_path, :virtual_path
    attr_reader :action, :prefix, :details

    def initialize(fullpath, relative_path)
      @fullpath = fullpath
      @relative_path = relative_path
      @virtual_path = relative_path.slice(0, relative_path.index("."))

      parsed = ParsedFilename.new(relative_path)
      @prefix = parsed.prefix
      @action = parsed.action
      @partial = parsed.partial?
      @details = parsed.details
    end

    def partial?
      @partial
    end
  end
end
