require "test_helper"

class ActionviewPrecompilerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ActionviewPrecompiler::VERSION
  end

  def test_precompile_works
    ActionviewPrecompiler.precompile
  end
end
