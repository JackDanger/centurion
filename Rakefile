require "bundler/gem_tasks"

require 'rake/clean'

directory 'js'
CLEAN.include 'public/script.js'

file 'public/script.js' => Dir.glob('js/*.coffee') do |t|
  sh "coffee --compile --join public/script.js #{t.prerequisites.join(' ')}"
end

task :default => 'public/script.js'
