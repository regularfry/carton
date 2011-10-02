module Carton

  # Wrapper around the amalgalite-pack binary
  class Amalgalite
    def initialize(fn_db)
      @fn_db = Path(fn_db)
    end
  
    def bin
      "amalgalite-pack"
    end

    def pack(opts)
      sh "#{bin} #{opts}"
    end
    
    def sh(cmd)
      puts cmd
      raise unless system cmd
    end
  
    def add(prefix, files)
      merged_files = [*files].join(" ")
      pack "--db #{@fn_db} --compress --strip-prefix #{prefix} #{merged_files}"
    end
    
    def merge(prefix, files)
      pack "--merge --db #{@fn_db} --compress --strip-prefix #{prefix} #{[*files].join(" ")}"
    end

    def add_self
      pack "--drop-table --db #{@fn_db} --self"
    end

  end


end # module Carton
