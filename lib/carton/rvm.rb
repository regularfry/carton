module Carton


  # Wrapper for the user's RVM installation, which we want to take
  # advantage of for its ruby- and extension-downloading capabilities.
  #
  # Here we assume that the user has already installed the ruby that
  # they want to use.  This means that the source *should* be
  # available at ~/.rvm/src.
  class RVM
    def self.rvm
      File.join(ENV['rvm_path'], "bin", "rvm")
    end

    def self.ruby_home
      home_line = `#{rvm} info homes | grep 'ruby:'`
      if home_line =~ /ruby:\s+"(.*)"/
        return $1.strip
      else
        return nil
      end
    end


    def self.current
      current_line = `#{rvm} current`.strip
      unless current_line.nil? || current_line.empty?
        return current_line
      end
    end
    
    def self.lib(libname)
      return File.join(ENV['rvm_path'], "usr", "lib", libname)
    end


    def self.install_package(package)
      system "#{rvm} package install #{package}"
    end

    def self.rebuild_ruby
      system "#{rvm} install #{current} --static"
    end


    def self.src
      File.join(ENV['rvm_path'], "src", self.current)
    end

 
    def self.ext_dir
      File.join(self.src, "ext")
    end
    
    def self.exts
      Exts.new(self.ext_dir)
    end



  end


end # module Carton
