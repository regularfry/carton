module Carton

  # Handler for a file tree of the Ruby source code.
  class Ruby
    attr_reader :root
    def initialize(root)
      @root = root
    end

    def fn(*args)
      File.expand_path(File.join(@root, *args))
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


    def make
      Dir.chdir(@root){ raise "Make failed" unless system "make" }
    end


  end


end # module Carton
