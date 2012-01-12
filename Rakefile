require "bundler/gem_tasks"

require 'rake/clean'

directory 'public'
directory 'build'

Application = "%{src,build}X.js"
Web         = "%{src/public,public}X.js"
Haml        = "%{src/public,public}X.html"
MakeScript  = FileList['src/*.coffee'].pathmap(Application) +
              FileList['src/public/*.coffee'].pathmap(Web)
MakeHtml    = FileList['src/**/*.haml'].pathmap(Haml)
p MakeScript
p MakeHtml

CLEAN.include MakeHtml
CLEAN.include MakeScript

desc "Compile coffescript files"
rule '.js' => ['%{build,src}X.js', '%{public,src/public}X.js'] do |t|
  sh "coffee --compile --join #{t.name} #{t.prerequisites.join(' ')}"
end

desc "Compile html files"
rule '.html' => ['%{public,src/public}X.html'] do |t|
  sh "haml #{t.prerequisites.join(' ')} > #{t.name}"
end

task :watch do
  `bundle exec watchr -e "watch('src/*') { %x{rake && touch config.ru} }"`
end

task :public => MakeScript
task :public => MakeHtml
task :default => :public
