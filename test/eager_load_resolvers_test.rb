require "test_helper"

module ActionviewPrecompiler
  class EagerLoadResolversTest < Minitest::Test
    def setup
      TemplateLoader.eager_loaded_resolvers.clear
    end

    def test_template_loader_eager_loads_resolvers_once_across_instances
      skip "Rails FileSystemResolver#eager_load_templates not available" unless
        ActionView::FileSystemResolver.method_defined?(:eager_load_templates)

      reset_action_view!

      resolver = ActionController::Base.view_paths.first
      resolver = resolver.resolver if resolver.respond_to?(:resolver)

      called = 0
      resolver.singleton_class.define_method(:eager_load_templates) do |view = nil|
        called += 1
        super(view)
      end

      TemplateLoader.new.eager_load_resolvers!
      TemplateLoader.new.eager_load_resolvers!

      assert_equal 1, called,
        "expected FileSystemResolver#eager_load_templates to be called at most once per resolver"
    end

    def test_precompile_run_still_compiles_scanned_templates
      reset_action_view!

      precompiler = Precompiler.new
      precompiler.scan_view_dir FIXTURES_VIEW_DIR

      compiled_templates = []
      callback = ->(_name, _start, _finish, _id, payload) do
        compiled_templates << payload[:virtual_path]
      end

      ActiveSupport::Notifications.subscribed(callback, "!compile_template.action_view") do
        precompiler.run
      end

      # The AST-based scan should still find and compile users/_user.
      assert_includes compiled_templates, "users/_user"
    end
  end
end
