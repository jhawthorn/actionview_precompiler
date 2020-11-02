require "test_helper"

module ActionviewPrecompiler
  class ASTParserTest < Minitest::Test
    include ASTParser

    def test_can_parse_render
      code = 'render "foo/bar"'
      assert parse_render_nodes(code).size == 1
    end

    def test_can_parse_render_parens
      code = 'render("foo/bar")'
      assert parse_render_nodes(code).size == 1
    end
  end
end
