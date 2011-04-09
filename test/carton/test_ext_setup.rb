require 'tempfile'

require 'test/helper'

require 'carton/ext_setup'

module TestCarton

  class TestExtSetup < Test::Unit::TestCase

    def test_enable_makes_sub
      Tempfile.new("test_ext_setup") do |f|
        f.puts("#thing")
        f.close
        
        ext_setup = ExtSetup.new(f.path)
        ext_setup.enable("thing")
        
        content = File.read(f.path)
        
        assert_match( %r{^thing$}, content )
      end
    end


    def test_enabled_lists_available
      Tempfile.new("test_ext_setup") do |f|
        f.puts("thing")
        f.close
        
        ext_setup = ExtSetup.new(f.path)

        available = ext_setup.enabled
        
        assert_equal %w{thing}, ext_setup.enabled
      end
    end


    def test_make_static_enables_nodynamoc
      Tempfile.new("test_ext_setup") do |f|
        f.puts("#option nodynamic")
        f.close
        
        ext_setup = ExtSetup.new(f.path)
        ext_setup.static!
        
        assert_match( /^option nodynamic$/,
                      File.read(f.path) )
      end
    end


  end # class TestExtSetup


end # module TestCarton
