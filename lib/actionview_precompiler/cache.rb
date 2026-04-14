require "json"
require "fileutils"

module ActionviewPrecompiler
  class Cache
    attr_reader :cache_path

    def initialize(cache_path, verbose: false)
      @cache_path = cache_path
      @verbose = verbose
    end

    def write(template_renders:, compiled_templates:)
      data = {
        "template_renders" => template_renders,
        "compiled_templates" => compiled_templates
      }
      FileUtils.mkdir_p(File.dirname(@cache_path))
      File.write(@cache_path, JSON.generate(data))
    end

    def read
      return nil unless File.exist?(@cache_path)
      JSON.parse(File.read(@cache_path))
    rescue JSON::ParserError
      nil
    end

    private

    def debug(msg)
      puts msg if @verbose
    end
  end
end
