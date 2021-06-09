require "test_helper"

module ActionviewPrecompiler
  class TemplateParserTest < Minitest::Test
    def test_parsing_template
      template = parse_template("users/show.html.erb")
      assert_equal "show.html.erb", template.basename
      assert_kind_of ActionView::Template::Handlers::ERB, template.handler

      renders = template.render_calls
      assert_equal 3, renders.length
      assert_equal ["users/_user", "users/_description", "users/_foo"], renders.map(&:virtual_path)
      assert_equal [[:user], [:bar], [:bar]], renders.map(&:locals_keys)
    end

    def test_parsing_partial
      template = parse_template("users/_user.html.erb")
      assert_equal "_user.html.erb", template.basename
      assert_kind_of ActionView::Template::Handlers::ERB, template.handler
      assert_equal [], template.render_calls
    end

    def test_parsing_ruby_template
      template = parse_template("users/plain_rubby.html.ruby")
      assert_equal "plain_rubby.html.ruby", template.basename
      renders =  template.render_calls
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path

      assert_equal [:user], renders[0].locals_keys
    end

    private

    def parse_template(filename)
      TemplateParser.new("#{FIXTURES_VIEW_DIR}/#{filename}")
    end
  end
end
