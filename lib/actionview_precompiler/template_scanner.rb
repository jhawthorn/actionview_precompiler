require "actionview_precompiler/template_file"

module ActionviewPrecompiler
  class TemplateScanner
    attr_reader :view_dir

    def initialize(view_dir)
      @view_dir = view_dir
    end

    def template_renders
      template_renders = []

      each_template do |template|
        parser = TemplateParser.new(template.fullpath)
        parser.render_calls.each do |render_call|
          virtual_path = render_call.virtual_path
          unless virtual_path.include?("/")
            # Not necessarily true, since the perfix is based on the current
            # controller, but is a safe bet most of the time.
            virtual_path = "#{template.prefix}/#{virtual_path}"
          end

          locals = render_call.locals_keys.map(&:to_s).sort

          template_renders << [virtual_path, locals]
        end
      end

      template_renders.uniq
    end

    private

    def each_template
      Dir["**/*", base: view_dir].sort.map do |file|
        fullpath = File.expand_path(file, view_dir)
        next if File.directory?(fullpath)

        yield TemplateFile.new(fullpath, file)
      end.compact
    end
  end
end
