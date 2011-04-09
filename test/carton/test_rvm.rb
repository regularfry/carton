require 'test/helper'

require 'carton/rvm'

module TestCarton
  
  class TestRVM < Test::Unit::TestCase
    C = Carton

    def test_bin_finds_binary
      filename = C::RVM.rvm
      
      assert_not_nil filename
      assert File.file?(filename)
      assert_equal "rvm", File.basename(filename)
    end
    

    def test_current_calls_rvm_current
      current = C::RVM.current

      assert_not_nil current
      assert_match( /[[:graph:]]/, current )
    end

    
    def test_lib_finds_a_lib
      assert_equal( "libz.a", 
                    File.basename(C::RVM.lib("libz.a")) )
    end


    def test_install_package_uses_name
      C::RVM.expects(:system).
        with( regexp_matches( /foo/ ) )
      C::RVM.install_package("foo")
    end

    
    def test_rebuild_ruby_uses_current_name
      C::RVM.stubs(:current).returns("foo")

      C::RVM.expects(:system).with(regexp_matches(/foo/))

      C::RVM.rebuild_ruby
    end



  end # class TestRVM


end # module TestCarton
