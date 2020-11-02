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

    def parse_render_nodes(code)
      ASTParser.parse_render_nodes(code)
    end
  end
end
