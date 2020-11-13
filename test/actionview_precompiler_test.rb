require "test_helper"

class ActionviewPrecompilerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ActionviewPrecompiler::VERSION
  end

  def test_precompile_works
    reset_action_view!

    compiled_templates = []
    callback = ->(name, start, finish, id, payload) do
      compiled_templates << payload[:virtual_path]
    end

    # We should compile the expected template
    ActiveSupport::Notifications.subscribed(callback, "!compile_template.action_view") do
      ActionviewPrecompiler.precompile
    end
    assert_includes compiled_templates, "users/_user"

    # There should be nothing to compile on a second run
    compiled_templates = []
    ActiveSupport::Notifications.subscribed(callback, "!compile_template.action_view") do
      ActionviewPrecompiler.precompile
    end
    assert_empty compiled_templates
  end
end
