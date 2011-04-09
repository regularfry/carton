require 'tmpdir'

require 'test/helper'

require 'carton/exts'

module TestCarton

  class TestExts < Test::Unit::TestCase
    
    C = Carton

    def test_libs_lists_static_only
      @dirname = File.join(Dir.tmpdir, "test_libs_lists_statics_only#{$$}")
      
      FileUtils.mkdir_p(@dirname)
      %w{libfoo.o libbar.a}.each do |filename|
        `touch #{File.join(@dirname, filename)}`
      end
      
      exts = C::Exts.new(@dirname)
      
      assert_equal( %W{#{File.join(@dirname, "libbar.a")}}, 
                    exts.libs)
    ensure
      FileUtils.rm_rf @dirname
    end


  end # TestExts

end # module TestCarton
