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
          @compile_params[p] = %x( #{@root}/miniruby -I #{@root} -rrbconfig -e 'puts Config::CONFIG["#{p}"] || ""' ).strip
        end
      end
      return @compile_params
    end

    def make(install_prefix)
      raise NotImplementedError.new(caller[0])
    end

    def includes
      raise NotImplementedError.new(caller[0])
    end

    def prepare
      raise NotImplementedError.new(caller[0])
    end


  end # class Ruby

  class Ruby19 < Ruby

    def includes
      (@root/".ext"/"include")["*"] + [@root/"include"]
    end

    def make(install_prefix)
      expanded_prefix = install_prefix.mkdir_p.expand
      
      @root.chdir{
        raise "Configure failed" unless 
          system "./configure "+
            "--with-static-linked-ext "+
            "--prefix=#{expanded_prefix}"

        raise "Make libruby-static.a failed" unless 
          system "make libruby-static.a exts" 
        #raise "Make ruby failed" unless system "make"
      }
      # Here we write a more appropriate extinit.c, overwriting the
      # original. This means that we actually initialise a different
      # set of extensions to the ruby binary, but that's unavoidable
      # for now.
      #
      self.exts.write_extinit_c
      @root.chdir {
        #Path("ext/extinit.o").rm_rf
        raise "Rebuilding extinit.o failed!" unless 
          system "make ext/extinit.o"
      }
      # This picks up everything and shoves it in the fakeroot.
      # Technically I don't *think* this is necessary, but it is
      # useful for debugging and for running tests against.
      @root.chdir{
        # This won't work until I sort out ffi
        #raise "Install failed" unless system "make install"
      }

    end


    def prepare
    end


  end # class Ruby19


  class Ruby18 < Ruby

    def includes
      [@root]
    end

    def make(install_prefix)
      expanded_prefix = install_prefix.mkdir_p.expand
      
      @root.chdir{
        raise "Configure failed" unless 
          system "./configure "+
            "--with-static-linked-ext "+
            "--prefix=#{expanded_prefix}"

        raise "Make libruby-static.a failed" unless 
          system "make libruby-static.a" 
        raise "Make ruby failed" unless system "make"
      }
      self.exts.write_extinit_c
      @root.chdir {
        Path("ext/extinit.o").rm_rf
        raise "Rebuilding extinit.o failed!" unless 
          system "make ext/extinit.o"
      }
      # This picks up everything and shoves it in the fakeroot.
      # Technically I don't *think* this is necessary, but it is
      # useful for debugging and for running tests against.
      @root.chdir{
        raise "Install failed" unless system "make install"
      }
    end


    def prepare
      patch_openssl()
    end


    private
    def patch_openssl
      # We need to clobber this otherwise the recursive
      # require breaks on OpenSSL::SSL::VERIFY_PEER in
      # the recursive require.
      @root.chdir {
        filename = "ext/openssl/ossl_digest.c"
        raise "Couldn't patch openssl" unless
          system "sed -i '/rb_require.\"openssl\"/d' #{filename}"
      }
    end


  end # class Ruby18


end # module Carton
