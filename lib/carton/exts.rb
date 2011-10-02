require 'rake'
require 'path'
require 'carton/ext_setup'

module Carton

  # Handler for ruby extensions. Can enable extensions by name (via an
  # ExtSetup object) pre-build and report on the available static libraries
  # post-build.
  class Exts
    attr_reader :path

    # `path` should be the path to the ext/ directory of
    # a ruby source tree.
    def initialize(path)
      @path = Path(path)
      @setup = ExtSetup.new(@path / "Setup")
    end


    def enable(*exts)
      @setup.enable(*exts)
      @setup.static!
    end
    

    def enabled
      return @setup.enabled().select do |line|
        prefix = @path / line.strip / "lib"
        prefix.directory?
      end
    end


    # Returns those extensions which are both
    # enabled in Setup and have a static build.
    def libs
      all_enabled = @setup.enabled
      if all_enabled.empty?
        return []
      else
        en = all_enabled.join(",")
        return FileList[@path / "{#{en}}" / "**" / "*.a"]
      end
    end


    def write_extinit_c
      (@path/"extinit.c").write(@setup.extinit_c)
    end


  end # class Exts 


end # module Cargon
