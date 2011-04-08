$:.unshift("lib")

require 'carton/version'

Gem::Specification.new do |s|
  s.name     = "carton"
  s.version  = Carton::VERSION
  s.summary  = "Static ruby application builder"
  s.email    = "alex@bytemark.co.uk"
  s.homepage = "http://github.com/bmalex/carton"
  s.description = "Carton compiles ruby source into a static, single-file binary executable."
  s.authors  = ["Alex Young"]

  s.bindir = "bin"
  s.executables = ["carton"]
  s.default_executable = "carton"

  s.has_rdoc = false

  # run git ls-files to get an updated list
  s.files = Dir['{bin,lib}/**/*.{rb,c}'] + %w{Rakefile}
end

