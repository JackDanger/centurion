if directory = ARGV.first
  root_path = File.expand_path directory
  file_paths = File.join root_path, '**/*.rb'
else
  puts 'USAGE: evaluate.rb /some/app'
  exit
end

Bundler.setup :default
require 'flog'
require 'mongo'
mongo = Mongo::Connection.new.db("centurion")
collection = mongo.collection(directory)

files = Dir.glob file_paths

files.each_with_index do |file, idx|
  whip = Flog.new
  whip.flog file
  whip.each_by_score do |class_method, score, call_list|
    collection.insert({
      :file       => file,
      :total      => whip.total,
      :average    => whip.average,
      :method     => class_method,
      :score      => score,
      :call_list  => Hash[call_list.sort_by { |k,v| -v }.map]
    })
  end
  puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{root_path}\//,'')}"
end