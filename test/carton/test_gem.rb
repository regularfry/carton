require 'test/helper'

require 'carton/gem'

module TestCarton
  
  class TestGem < Test::Unit::TestCase

    C = Carton

    def test_gem_spec_finds_a_spec
      gem = C::Gem.new("mocha") # since we require it anyway
      
      assert_not_nil spec = gem.gem_spec
      assert_equal "mocha", spec.name
    end

    
    def test_exists_finds_mocha
      assert C::Gem.new("mocha").exists?
    end

    
    def test_exists_doesnt_find_mochan
      assert !C::Gem.new("mochan").exists?
    end

    
    def test_root_returns_a_gem_home
      gem = C::Gem.new("mocha")
      assert_match %r{mocha}, gem.root
      assert File.directory? gem.root
    end


    def test_class_install_calls_gem_install
      C::Gem.expects(:system).
        with( regexp_matches( /^gem install/ ) )

      C::Gem.install("mocha")
    end


    def test_instance_install_calls_gem_install
      C::Gem.expects(:system).
        with( regexp_matches( /^gem install/ ) )

      C::Gem.new("mocha").install
    end


    def test_instance_install_uses_name
      C::Gem.expects(:system).
        with( regexp_matches( /install mocha/ ) )
      C::Gem.install("mocha")
    end


  end # class TestGem


end # module TestCarton
