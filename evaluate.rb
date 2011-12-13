Bundler.setup :default

if directory = ARGV.first
  root_path = File.expand_path directory
  file_paths = File.join root_path, '**/*.rb'
else
  puts 'USAGE: evaluate.rb /some/app'
  exit
end


files = Dir.glob file_paths

files.each_with_index do |file, idx|
  puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{root_path}\//,'')}"
end