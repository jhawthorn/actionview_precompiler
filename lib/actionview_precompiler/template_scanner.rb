require "actionview_precompiler/template_file"

module ActionviewPrecompiler
  class TemplateScanner
    attr_reader :view_dir, :strict_locals_paths

    def initialize(view_dir)
      @view_dir = view_dir
      @strict_locals_paths = []
    end

    def template_renders
      template_renders = []

      each_template do |template|
        if strict_locals?(template)
          @strict_locals_paths << template.virtual_path
          template_renders << [template.virtual_path, []]
        end

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

    def strict_locals?(template)
      defined?(ActionView::Template::STRICT_LOCALS_REGEX) &&
        File.read(template.fullpath).match?(ActionView::Template::STRICT_LOCALS_REGEX)
    end

    def each_template
      Dir["**/*", base: view_dir].sort.map do |file|
        fullpath = File.expand_path(file, view_dir)
        next if File.directory?(fullpath)

        yield TemplateFile.new(fullpath, file)
      end.compact
    end
  end
end
