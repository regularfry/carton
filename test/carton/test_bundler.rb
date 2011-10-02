require 'test/helper'

require 'carton/bundler'

module TestCarton

  class TestBundler < Test::Unit::TestCase
  
    C = Carton

    def test_has_bundler
      assert_not_nil C::Bundler
    end
  end


end # module TestCarton
