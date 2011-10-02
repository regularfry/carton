require 'path'
require 'carton/exts'

module Carton

  # Handler for a file tree of the Ruby source code.
  class Ruby
    attr_reader :root
    def initialize(root)
      @root = Path(root)
    end

    def fn(*args)
      args.inject(root){|path, component| path/component}
    end

    def fn_stdlib
      fn("lib")
    end

    def fn_ext
      fn("ext")
    end
    
    def exts
      Exts.new(fn_ext)
    end

    
    def rbconfig
      unless (@compile_params ||= false)
        @compile_params = {}
        %w[ CC CFLAGS XCFLAGS LDFLAGS CPPFLAGS LIBS ].each do |p|
          @compile_params[p] = %x( ruby -r#{fn("rbconfig")} -e 'puts Config::CONFIG["#{p}"] || ""' ).strip
        end
      end
      return @compile_params
    end


    def make(install_prefix)
      install_prefix.mkdir_p
      @root.chdir{
        raise "Configure failed" unless 
          system "./configure "+
            "--with-static-linked-ext "+
            "--prefix=#{install_prefix.expand}"

        raise "Make libruby-static.a failed" unless 
          system "make libruby-static.a" 
        raise "Make ruby failed" unless system "make"
        # This picks up everything and shoves it in the fakeroot.
        # Technically I don't *think* this is necessary, but it is
        # useful for debugging and for running tests against.
        raise "Install failed" unless system "make install"
      }
      # Here we write a more appropriate extinit.c, overwriting the
      # original. This means that we actually initialise a different
      # set of extensions to the ruby binary, but that's unavoidable
      # for now.
      #
      self.exts.write_extinit_c
      @root.chdir {
        Path("ext/extinit.o").rm_rf
        raise "Rebuilding extinit.o failed!" unless 
          system "make ext/extinit.o"
      }
    end


  end


end # module Carton
