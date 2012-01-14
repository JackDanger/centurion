require "bundler/gem_tasks"

require 'rake/clean'

directory 'public'

Application = FileList['src/*.coffee'].pathmap("%{src,public}X.js")
Haml        = FileList['src/*.haml'].pathmap("%{src,public}X.html")

CLEAN.include Application
CLEAN.include Haml

desc "Compile Application Coffeescript files"
rule '.js' => ['%{public,src}X.coffee'] do |t|
  sh "coffee --compile -o #{File.dirname t.name} #{t.prerequisites.join(' ')}"
end

desc "Compile html files"
rule '.html' => ['%{public,src}X.haml'] do |t|
  sh "haml #{t.prerequisites.join(' ')} > #{t.name}"
end

task :watch do
  exec %Q[bundle exec watchr -e "watch('src/.*') { %x{rake public upload} }"]
end

task :upload do
  riak = ENV['RIAK'] || 'http://localhost:8098/riak/app'

  Dir.glob("public/*").each do |file|
    type = case file
           when /.css$/
             'text/css'
           when /.js$/
             'text/javascript'
           when /.html/
             'text/html'
           end
    filename = File.basename file
    sh "curl -s -X POST -H Content-Type:#{type} #{riak}/#{filename} --data-binary @#{file}"
  end
end

task :public => Application
task :public => Haml
task :default => :public
