require 'rake'
require 'carton/ext_setup'

module Carton

  # Handler for ruby extensions. Can enable extensions by name (via an
  # ExtSetup object) pre-build and report on the available static libraries
  # post-build.
  class Exts
    attr_reader :path

    def initialize(path)
      @path = path
      @setup = ExtSetup.new(File.join(path, "Setup"))
    end


    def enable(*exts)
      @setup.enable(*exts)
      @setup.static!
    end
    

    def enabled
      return @setup.enabled().select do |line|
        prefix = File.join( File.dirname(@path), line.strip, "lib" )
        File.directory?( prefix )
      end
    end


    def libs
      FileList[File.join(@path, "**", "*.a")]
    end


  end # class Exts 


end # module Cargon
