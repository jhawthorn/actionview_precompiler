require "test_helper"

module ActionviewPrecompiler
  class ControllerScannerTest < Minitest::Test
    def test_finds_users_show
      scanner = ControllerScanner.new(FIXTURES_CONTROLLER_DIR)
      renders = scanner.template_renders

      assert_includes renders, ["users/show", []]
    end

    def test_finds_explicit_with_locals
      scanner = ControllerScanner.new(FIXTURES_CONTROLLER_DIR)
      renders = scanner.template_renders

      assert_includes renders, ["users/_with_locals", ["user"]]
    end

    def test_finds_layout
      scanner = ControllerScanner.new(FIXTURES_CONTROLLER_DIR)
      renders = scanner.template_renders

      assert_includes renders, ["layouts/site", []]
    end
  end
end
