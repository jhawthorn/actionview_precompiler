require "test_helper"

module ActionviewPrecompiler
  class PrecompilerTest < Minitest::Test
    def test_each_template_render
      precompiler = Precompiler.new([FIXTURES_DIR])
      lookup_args = precompiler.each_template_render.to_a
      lookup_args.map! {|template, locals| [template.virtual_path, locals] }

      expected_render = ["users/_user", ["user"]]
      assert_includes lookup_args, expected_render
    end

    def test_precompiler_run
      reset_action_view!

      precompiler = Precompiler.new([FIXTURES_DIR])

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

    def test_precompiles_no_locals_paths
      reset_action_view!

      precompiler = Precompiler.new([FIXTURES_DIR])
      precompiler.no_locals_paths = ["layouts/site"]

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
