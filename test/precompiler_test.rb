require "test_helper"

module ActionviewPrecompiler
  class PrecompilerTest < Minitest::Test
    def test_precompiler
      precompiler = Precompiler.new([FIXTURES_DIR])
      lookup_args = precompiler.each_lookup_args.to_a

      expected_details = { locale: [], variants: [], formats: [:html], handlers: [:erb] }
      expected = ["user", "users", true, expected_details , nil, ["user"]]
      assert_includes lookup_args, expected
    end
  end
end
