module Carton
  
  # Handler for ruby/ext/Setup, for enabling extensions and 
  # static options prior to a build
  class ExtSetup
    def initialize(filename)
      @filename=filename
    end

    def enable(*exts)
      exts.each do |ext|
        quoted_ext = ext.gsub(%r{/}, '\\/')
        system "sed -i 's/^\##{quoted_ext}$/#{quoted_ext}/' #{@filename}"
      end
    end


    def enabled
      result = []
      raise "#{@filename} doesn't exist!" unless File.file?(@filename)
      File.open(@filename) do |f|
        f.each_line do |line|
          next if line =~ /\Aoption/
          next if line.strip.length == 0
          next if line =~ /\A#/

          result << line.strip
        end
      end
      result
    end

    def static!
      enable("option nodynamic")
    end


  end # class ExtSetup


end # module Carton
