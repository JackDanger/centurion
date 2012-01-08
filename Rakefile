require "bundler/gem_tasks"

require 'rake/clean'

directory 'public'

Coffee = FileList['src/*.coffee'].pathmap("%{src,public}X.js")
Haml   = FileList['src/*.haml'].pathmap("%{src,public}X.html")

CLEAN.include Haml
CLEAN.include Coffee

desc "Compile coffescript files"
rule '.js' => ['%{public,src}X.coffee'] do |t|
  sh "coffee --compile --join #{t.name} #{t.prerequisites.join(' ')}"
end

desc "Compile html files"
rule '.html' => ['%{public,src}X.haml'] do |t|
  sh "haml #{t.prerequisites.join(' ')} > #{t.name}"
end

task :watch do
  `bundle exec watchr -e "watch('src/*') { %x{rake} }"`
end

task :public => Coffee
task :public => Haml
task :default => :public
