require 'test/helper'

require 'carton/amalgalite'

module TestCarton
  
  class TestAmalgalite < Test::Unit::TestCase
    C = Carton

    def setup
      @amalgalite_gem = Gem.source_index.find_name("amalgalite").first
      fail "No amalgalite gem!" unless @amalgalite_gem
      @am = C::Amalgalite.new(nil)
    end


    def test_bin_matches_amalgalite_gem
      exename = @amalgalite_gem.executable
      assert_equal exename, @am.bin
    end


    def test_pack_runs_bin
      matcher = @amalgalite_gem.executable
      @am.expects(:sh).with(regexp_matches(%r{#{matcher}}))
      @am.pack("")
    end


    def test_includes_opts
      @am.expects(:sh).with(regexp_matches(%r{foo}))
      @am.pack("foo")
    end

    
    def test_add_uses_prefix
      @am.expects(:sh).with(regexp_matches(%r{prefix}))
      @am.add("prefix", "file")
    end

    
    def test_add_uses_file
      @am.expects(:sh).with(regexp_matches(%r{filename}))
      @am.add("", "filename")
    end

    
    def test_add_uses_file_list
      @am.expects(:sh).with(regexp_matches(%r{foo bar}))
      @am.add("", %w{foo bar})
    end

    
    def test_add_self_includes_self
      @am.expects(:sh).with(regexp_matches(%r{--self}))
      @am.add_self
    end

    
    def test_new_uses_db_filename_for_add_self
      new_am = C::Amalgalite.new("foo.db")
      new_am.expects(:sh).with(regexp_matches(%r{foo.db}))
      new_am.add_self
    end
    

    def test_new_uses_db_filename_for_merge
      new_am = C::Amalgalite.new("foo.db")
      new_am.expects(:sh).with(regexp_matches(%r{foo.db}))
      new_am.merge("", "")      
    end

    
    def test_new_uses_db_filename_for_add
      new_am = C::Amalgalite.new("foo.db")
      new_am.expects(:sh).with(regexp_matches(%r{foo.db}))
      new_am.add("","")
    end


  end # class TestAmalgalite


end # module TestCarton

