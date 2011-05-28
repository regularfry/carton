require 'rake'
require "rake/tasklib"
require 'rubygems'

$cc = ENV['CC']
if $cc.nil? || $cc.empty?
  $cc = 'gcc'
end


class Rake::FileTask
  def check!
    raise "Creating #{self.name} failed!" unless
      File.exists?(self.name)
  end
end


module Carton
  
  # Wrap the objcopy command, hopefully also picking the correct
  # binary format and target
  class Objcopy
    def initialize
      
      # @bfdarch = "i386"
      # @bfdtarget="elf64-x86-64"
      # @bfdtarget="elf32-i386"

      header, @bfdtarget,meta, @bfdarch  = `objdump -i 2> /dev/null`.split("\n")[0..3].map{|s| s.strip}
      raise "Bad bfdtarget (#{@bfdtarget.inspect})!" unless @bfdtarget
      raise "Bad bfdarch (#{@bfdarch.inspect})!" unless @bfdarch
    end
    
    def import(infile, outfile)
      sh "objcopy -Ibinary -O  #{@bfdtarget} -B #{@bfdarch} #{infile} #{outfile}"
    end
  end

  class Task < Rake::TaskLib

    def initialize(build_path, outputfile, appfile, include_files, load_path)
      @build_dir = build_path
      @ruby = Ruby.new(fn_build_file("ruby"))
      @gems_needed = File.file?("Gemfile")
      define(outputfile, appfile, include_files, load_path)
    end


    def fn_rvm_amalgalite_static
      amalgalite = Gem.new("amalgalite")
      return File.join(amalgalite.root, "ext", "amalgalite", "amalgalite3.o")
    end


    # The path into the build directory for the given filename
    def fn_build_file(*filenames)
      directory @build_dir
      result = File.join(@build_dir, *filenames)
      file result => @build_dir
      return result
    end


    def pack_ruby(am_db)
      fn_prefix = @ruby.fn_stdlib
      am_db.add(fn_prefix, fn_prefix)
    end


    def pack_rbconfig(am_db)
      fn_rbconfig = @ruby.fn("rbconfig")
      am_db.add(File.dirname(fn_rbconfig), fn_rbconfig)
    end


    def exts
      @exts ||= @ruby.exts
    end

    def pack_exts(am_db)
      exts.enabled.each do |fn_lib|
        am_db.merge(fn_lib, fn_lib)
      end
    end

    def pack_amalgalite(am_db)
      am_db.add_self
    end

    # load_path is expected to be a colon-separated
    # set of paths
    def pack_app_files(am_db, glob, load_path="lib:.")
      load_paths_arr = load_path.split(":").
        map{|lp| File.expand_path(lp)}

      expanded_glob = File.expand_path(glob)

      Dir[expanded_glob].each do |filename|
        # ok, now which load_path entry do I want?
        prefix = load_paths_arr.find{|lp|
          filename.start_with?(lp)
        }
        # No prefix? Pretend we're 1.8 and use pwd
        prefix ||= Dir.pwd
        
        am_db.add(prefix, filename)
      end
    end

    def with_tempfile(orig_name)
      tmpname = orig_name + ".tmp"
      rm_f tmpname
      yield tmpname
      FileUtils.mv tmpname, orig_name
    end


    def file_copy(from, to)
      file to => from do |t|
        sh "cp #{from} #{to}"
        t.check!
      end
    end


    def amalgalite_objects
      amalgalite = Gem.new("amalgalite")
      amalgalite.install unless amalgalite.exists?
      FileList[File.join(amalgalite.root, "ext", "amalgalite", "*.o")]
    end


    def fn_carton_boot_c
      dirname = File.join(File.dirname(__FILE__),'..')
      return File.expand_path(File.join(dirname, "carton_boot.c"))
    end


    def define(outputfile, appfile, include_files, load_path)

      # These are the default extensions which crate builds, I'll sort
      # out a different mechanism for specifying these later
      allowed_exts = %w{
          bigdecimal
          digest
          digest/md5
          digest/sha1
          enumerator
          etc
          fcntl
          iconv
          io/wait
          nkf
          socket
          stringio
          strscan
          syck
          thread
          zlib
        }
#          openssl # because I can't get this working yet

      desc "Copy RVM's cache of the ruby source into our build directory"
      # This is needed otherwise we risk clobbering the *current* ruby,
      # which would be Bad.
      file @ruby.root do |t|
        sh "cp -a #{RVM.src} #{t.name}"
        # Clear this out because chances are that our build
        # choices won't match RVM's, and it might not get 
        # rebuilt unless it's absent
        rm_f @ruby.fn("libruby-static.a")

        t.check!
      end
   

      file( @ruby.fn("libruby-static.a") => 
            @ruby.root ) do |t|

        @ruby.exts.enable(*allowed_exts)
        @ruby.make
        
        t.check!
      end


      file RVM.lib("libz.a") do |t|
        RVM.install_package("zlib")
        t.check!
      end
      
      # The install_package task here can't rationally be shared
      # because adding a basic task as a prerequisite to both triggers
      # a rebuild every invocation. This is because basic tasks have a
      # timestamp of Time.now, which will be after the timestamps of
      # the file tasks.
      file RVM.lib("libcrypto.a") do |t|
        RVM.install_package("openssl")
        t.check!
      end

      file RVM.lib("libssl.a") do |t|
        RVM.install_package("openssl")
        t.check!
      end



      file fn_build_file("libamalgalite3.a") => amalgalite_objects do |t|
        sh "ar rcs #{t.name} #{amalgalite_objects.join(" ")}"
        t.check!
      end


      {
        "libz.a"           => RVM.lib("libz.a"),
        "libssl.a"         => RVM.lib("libssl.a"),
        "libcrypto.a"      => RVM.lib("libcrypto.a"),
        "libruby-static.a" => @ruby.fn("libruby-static.a"),
        "extinit.o"        => @ruby.fn("ext","extinit.o")
      }.
        each_pair do |to, from|
        file_copy(from, fn_build_file(to))
      end



      file fn_build_file("lib.db") do |t|
        with_tempfile(t.name) do |tmpname|

          am_lib = Amalgalite.new(tmpname)
          pack_ruby(am_lib)
          pack_rbconfig(am_lib)
          pack_exts(am_lib)
          pack_amalgalite(am_lib)

        end

        t.check!
      end


      file appfile

      file fn_build_file("app.db") => FileList[*include_files] << appfile do |t|
        with_tempfile(t.name) do |tmpname|
          am_lib = Amalgalite.new(tmpname)
          
          include_files.each do |glob|
            # We need to use the load_path here for the include
            # files, because they're going to be required by the
            # appfile based on LOAD_PATH
            pack_app_files(am_lib, glob, load_path)
          end
          # We don't bother with load_path here, because it's
          # the entry point and *presumably* we don't need
          # to care that nothing else can necessarily find it.
          pack_app_files(am_lib, appfile)

        end
        t.check!
      end

      @fn_gemdir = fn_build_file("gems")
      directory @fn_gemdir

      file @fn_gemdir => FileList["Gemfile"].existing do |t|
        # First, install the gems into the build dir
        # Use bundler to grab the gems, but gem itself
        # to do the install. This is needed because
        # bundler remembers install paths in a way
        # that can't be undone except by doing another
        # bundle install.
        # The downside to this is that it can't (I
        # don't think) be done offline.
        mkdir_p( @fn_gemdir )
        if File.file?("Gemfile")
          sh "bundle package"
          fns_gem_files = FileList['vendor/cache/*.gem']
          cmd = %W{gem install #{fns_gem_files.join(" ")} 
                  --install-dir #{t.name}
                  --no-rdoc --no-ri}.join(" ")
          sh cmd
        end
      end


      # TODO: This needs factoring out
      file fn_build_file("gem.db") => @fn_gemdir do |t|
        begin
          ::Gem.use_paths(@fn_gemdir)
          si = ::Gem.source_index
          # Cache the files so we minimise the calls to am.add
          full_lib_files = Hash.new{|h,k| h[k]=Array.new}

          # For each gem which got installed,
          si.all_gems.values.each do |gemspec|
            # Figure out the correct prefix and add to am
            gemspec.require_paths.each do |load_path|
              prefix = File.join(gemspec.full_gem_path, load_path)
              Dir.chdir(prefix) do
                Dir['**/*'].each do |lib_file|
                  full_lib_files[prefix] << lib_file
                end
              end

            end # catch :done

          end # all_gems.values.each

          with_tempfile(t.name) do |tmpname|
            am = Amalgalite.new(tmpname)

            full_lib_files.each_pair do |prefix, filenames|
              am.add(prefix, filenames)
            end

          end # with_tempfile
        
        ensure
          ::Gem.clear_paths
        end
        t.check!
        # TODO: Figure out what to do with extensions.
      end


      fns_code_obj = [sqldump_obj( fn_build_file("lib.db") ),
                      @gems_needed ? sqldump_obj( fn_build_file("gem.db") ) : nil,
                      sqldump_obj( fn_build_file("app.db") )].compact


      file fn_build_file("librubycode.a") => fns_code_obj do |t|
        sh "ar rcs #{t.name} #{fns_code_obj.join(" ")}"
        t.check!
      end




      file fn_build_file("carton_boot.o") => fn_carton_boot_c() do |t|
        opts = %W{-D'CARTON_ENTRY="#{appfile}"'
                  #{@gems_needed ? "-DWITH_GEMS" : ""}
                  -c #{fn_carton_boot_c()}
                  #{@ruby.rbconfig['CFLAGS']}
                  #{@ruby.rbconfig['XCFLAGS']}
                  #{@ruby.rbconfig['CPPFLAGS']}
                  -I #{@ruby.root}
                  -o #{t.name}
        }
        sh "#{@ruby.rbconfig['CC']} #{opts.join(" ")}"
        t.check!
      end
      
      libs = %w{ssl
                crypto
                z
                ruby-static
                rubycode
                amalgalite3
      }
      objs = %w{
                carton_boot
      }.map{|o| o+".o"}

      obj_files = (libs.map{|l| "lib#{l}.a"}+objs).
        map{|f| fn_build_file(f)}


      desc "Build the static objects"
      task :obj_files => obj_files + [fn_build_file("extinit.o")]

      directory File.dirname(outputfile)

      desc "Build the executable"
      file outputfile => [:obj_files, File.dirname(outputfile)] do |t|
        # These should be another task, but since we can't know ahead of time what .a files 
        # the ruby build is actually going to produce, we can't build it.
        fns_exts = @ruby.exts.libs
          
        lib_opts = libs.map{|l| "-l"+l}.join(" ")
        ruby_link_opts = @ruby.rbconfig['LIBS']
        sh %W{gcc -static 
              #{fn_build_file("extinit.o")} 
              #{fns_exts.join(" ")} 
              #{objs.map{|o| fn_build_file(o)}.join(" ")}
              -L#{@build_dir}
              #{lib_opts}
              #{ruby_link_opts}
              -o #{t.name}}.join(" ")

        t.check!
        puts "#{t.name} built."
      end
      
      self
    end


    def sqldump_obj(fn_db)
      name = File.basename(fn_db, ".db")
      fn_sql = fn_build_file("#{name}.sql")
      fn_obj = fn_build_file("#{name}.o")

      file fn_sql => fn_db do |t|
        sh "sqlite3 #{fn_db} '.dump' > #{fn_sql}"
        t.check!
      end

      file fn_obj => fn_sql do |t|
        target = File.expand_path(t.name)
        Dir.chdir(File.dirname(fn_sql)) do
          Objcopy.new.import(File.basename(fn_sql), target)
        end
        t.check!
      end
    end


  end # class Task


end # module Carton
