require "test_helper"

module ActionviewPrecompiler
  class PrecompilerTest < Minitest::Test
    def test_each_template_render
      precompiler = Precompiler.new
      precompiler.scan_view_dir FIXTURES_VIEW_DIR
      template_renders = precompiler.template_renders

      expected_render = ["users/_user", ["user"]]
      assert_includes template_renders, expected_render
    end

    def test_precompiler_run
      reset_action_view!

      precompiler = Precompiler.new
      precompiler.scan_view_dir FIXTURES_VIEW_DIR

      compiled_templates = []
      callback = ->(name, start, finish, id, payload) do
        compiled_templates << payload[:virtual_path]
      end
      ActiveSupport::Notifications.subscribed(callback, "!compile_template.action_view") do
        precompiler.run
      end

      # Make sure we find and compile users/_user
      assert_includes compiled_templates, "users/_user"
    end

    def test_precompiles_static_paths
      reset_action_view!

      precompiler = Precompiler.new
      precompiler.add_template("layouts/site")

      compiled_templates = []
      callback = ->(name, start, finish, id, payload) do
        compiled_templates << payload[:virtual_path]
      end
      ActiveSupport::Notifications.subscribed(callback, "!compile_template.action_view") do
        precompiler.run
      end

      # Make sure we find and compile layout even without locals set
      assert_includes compiled_templates, "layouts/site"
    end
  end
end
