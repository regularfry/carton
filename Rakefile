require 'rake/testtask'

desc "Build the gem"
task :gem do
  sh "gem build carton.gemspec"
end



Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = true
end
