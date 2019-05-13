require "test_helper"

module ActionviewPrecompiler
  class ASTParserTest < Minitest::Test
    include ASTParser

    def test_can_parse_this_file
      node = parse(File.read(__FILE__))
      assert node?(node)
    end

    def test_can_parse_render
      node = parse('render "foo/bar"')
      assert node?(node)
    end
  end
end
