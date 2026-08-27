module ActionviewPrecompiler
  class TemplateLoader
    VIRTUAL_PATH_REGEX = %r{\A(?:(?<prefix>.*)\/)?(?<partial>_)?(?<action>[^\/\.]+)}

    # Rails' FileSystemResolver#eager_load_templates unconditionally rebuilds
    # unbound templates and recompiles them each time it's called. Track the
    # resolvers we've already prewarmed so repeated Precompiler runs don't
    # re-do that work.
    @eager_loaded_resolvers = Set.new
    class << self
      attr_reader :eager_loaded_resolvers
    end

    def initialize
      target = ActionController::Base
      @lookup_context = ActionView::LookupContext.new(target.view_paths)
      @view_context_class = target.view_context_class
    end

    # Warm every FileSystemResolver's unbound-template cache in a single
    # directory walk using Rails' own +FileSystemResolver#eager_load_templates+.
    # Subsequent +load_template+ calls then hit an in-memory cache instead of
    # re-globbing the view directory once per virtual path, and the empty-
    # locals variant of each template is compiled up front.
    #
    # No-op on Rails versions that don't ship +eager_load_templates+, and no-op
    # for any resolver we've already prewarmed in this process.
    def eager_load_resolvers!
      return unless defined?(ActionView::FileSystemResolver) &&
        ActionView::FileSystemResolver.method_defined?(:eager_load_templates)

      view = nil
      @lookup_context.view_paths.each do |resolver|
        resolver = resolver.resolver if resolver.respond_to?(:resolver)
        next unless resolver.is_a?(ActionView::FileSystemResolver)
        next unless self.class.eager_loaded_resolvers.add?(resolver.object_id)

        view ||= @view_context_class.new(@lookup_context, {}, nil)
        resolver.eager_load_templates(view)
      end
    end

    def load_template(virtual_path, locals)
      templates = find_all_templates(virtual_path, locals)
      templates.each do |template|
        template.send(:compile!, @view_context_class)
      end
    end

    private

    def find_all_templates(virtual_path, locals)
      match = virtual_path.match(VIRTUAL_PATH_REGEX)
      if match
        action = match[:action]
        prefix = match[:prefix] ? [match[:prefix]] : []
        partial = !!match[:partial]

        # Assume templates with different details take same locals
        details = {}

        @lookup_context.find_all(action, prefix, partial, locals, details)
      else
        []
      end
    end
  end
end
