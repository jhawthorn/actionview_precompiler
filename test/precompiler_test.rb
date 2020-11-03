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
      precompiler = Precompiler.new([FIXTURES_DIR])
      precompiler.run
    end
  end
end
