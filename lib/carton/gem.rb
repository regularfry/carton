module Carton

  # Class for handling (and installing) gems.
  class Gem
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def gem_spec
      # Here we do actually need rubygems as a library.
      require 'rubygems'
      
      raise "Gem #{name} not found!" unless
        @gem_spec ||= ::Gem.source_index.find_name(name).last
      @gem_spec
    end
    
    def exists?
      gem_spec() && true rescue nil
    end

    def root
      File.join(gem_spec().full_gem_path)
    end

    def install
      self.class.install(self.name)
    end

    def self.install(name)
      system "gem install #{name} --no-rdoc --no-ri"
      return new(name)
    end

      
  end # class Gem


end # module Carton
