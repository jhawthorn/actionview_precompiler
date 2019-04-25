module ActionviewPrecompiler
  class Precompiler
    class Template
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

    attr_reader :templates

    def initialize(view_dirs)
      @templates =
        view_dirs.flat_map do |view_dir|
          Dir["**/*", base: view_dir].map do |file|
            fullpath = File.expand_path(file, view_dir)
            next if File.directory?(fullpath)

            Template.new(fullpath, file)
          end.compact
        end

      determine_locals
    end

    def each_lookup_args
      return enum_for(__method__) unless block_given?

      each_template_render do |template, locals|
        details = {
          locale: Array(template.details[:locale]),
          variants: Array(template.details[:variant]),
          formats: Array(template.details[:format]),
          handlers: Array(template.details[:handler])
        }

        yield [template.action, template.prefix, template.partial?, locals, details]
      end

      nil
    end

    def each_template_render
      return enum_for(__method__) unless block_given?

      @templates.each do |template|
        locals_set = @locals_sets[template.virtual_path]
        if locals_set
          locals_set.each do |locals|
            yield template, locals
          end
        elsif !template.partial?
          # For now, guess that non-partials we haven't seen take no locals
          yield template, []
        else
          # Locals unknown
        end
      end
    end

    def determine_locals
      @locals_sets = {}

      @templates.each do |template|
        parser = TemplateParser.new(template.fullpath)
        parser.render_calls.each do |render_call|
          @locals_sets[render_call.virtual_path] ||= []
          @locals_sets[render_call.virtual_path] << render_call.locals_keys.map(&:to_s).sort
        end
      end

      @locals_sets.each_value(&:uniq!)
    end
  end
end
