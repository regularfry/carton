require 'tmpdir'

require 'test/helper'

require 'carton/exts'

module TestCarton

  class TestExts < Test::Unit::TestCase
    
    C = Carton

    def test_libs_lists_static_only
      @dir = Path(Dir.tmpdir) /  "test_libs_lists_statics_only#{$$}"
      
      (@dir/"Setup").write("foo\nbar")
      (@dir/"foo"/"libfoo.o").touch
      (@dir/"bar"/"libbar.a").touch
      
      exts = C::Exts.new(@dir.to_s)
      
      assert_equal( %W{#{@dir/"bar"/"libbar.a"}}, exts.libs)
    ensure
      @dir.rm_rf
    end


  end # TestExts

end # module TestCarton
