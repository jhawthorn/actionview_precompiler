require "test_helper"

module ActionviewPrecompiler
  class HelperScannerTest < Minitest::Test
    def test_finds_users_show
      scanner = HelperScanner.new(FIXTURES_HELPER_DIR)
      renders = scanner.template_renders

      assert_includes renders, ["users/_info", ["user"]]
    end
  end
end
