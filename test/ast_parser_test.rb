require "test_helper"

module ActionviewPrecompiler
  class ASTParserTest < Minitest::Test
    def test_can_parse_render
      code = 'render "foo/bar"'
      assert parse_render_nodes(code).size == 1
    end

    def test_can_parse_render_parens
      code = 'render("foo/bar")'
      assert parse_render_nodes(code).size == 1
    end

    def test_can_parse_render_instance_variable
      code = 'render @foo'
      assert parse_render_nodes(code).size == 1
    end

    def test_raises_compilation_error
      code = '<<><><><>>'

      err = assert_raises(ActionviewPrecompiler::CompilationError) do
        parse_render_nodes(code)
      end

      assert_equal err.message, "Unable to parse the template in test_file.rb"
    end

    def parse_render_nodes(code)
      ASTParser.parse_render_nodes(code, "test_file.rb")
    end
  end
end
