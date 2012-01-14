require "bundler/gem_tasks"

require 'rake/clean'

directory 'public'
directory 'build'

Application = FileList['src/*.coffee'].pathmap("%{src,build}X.js")
Web         = FileList['src/public/*.coffee'].pathmap("%{src/public,public}X.js")
Haml        = FileList['src/*.haml'].pathmap("%{src,public}X.html")

CLEAN.include Application
CLEAN.include Web
CLEAN.include Haml

desc "Compile Application Coffeescript files"
rule '.js' => ['%{build,src}X.coffee'] do |t|
  sh "coffee --compile -o #{File.dirname t.name} #{t.prerequisites.join(' ')}"
end

desc "Compile Web Coffeescript files"
rule '.js' => ['%{public,src/public}X.coffee'] do |t|
  sh "coffee --compile --join #{t.name} #{t.prerequisites.join(' ')}"
end

desc "Compile html files"
rule '.html' => ['%{public,src/public}X.haml'] do |t|
  sh "haml #{t.prerequisites.join(' ')} > #{t.name}"
end

task :watch do
  `bundle exec watchr -e "watch('src/.*\/?.*') { %x{rake && touch config.ru} }"`
end

task :upload do
  riak = ENV['RIAK'] || 'http://localhost:8098/riak/app'

  Dir.glob("public/*").each do |file|
    type = case file
           when /.css$/
             'text/stylesheet'
           when /.js$/
             'text/javascript'
           when /.html/
             'text/html'
           end
    filename = File.basename file
    sh "curl -X POST -H Content-Type:#{type} #{riak}/#{filename} --data-binary @#{file}"
  end
end

task :public => Application
task :public => Web
task :public => Haml
task :default => :public
