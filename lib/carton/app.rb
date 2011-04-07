require 'rake'
require 'carton/task'


module Carton

  class App
    
    def initialize
      @app = Rake.application
      @app.init("carton")
    end

    def run(build_path, outputfile, appfile, include_files)
      # HACKHACKHACK
      p build_path
      p outputfile
      p appfile
      if build_path && outputfile && appfile
        Task.new(build_path, outputfile, appfile, include_files)
        @app.invoke_task(outputfile)
      else
        help()
      end
    end

    def help
      @app.display_tasks_and_comments
    end


  end # class App


end
