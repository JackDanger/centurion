require 'rubygems'
gem 'yajl-ruby'
require 'riak'
require 'yajl'
riak = Riak::Client.new
bucket = riak.bucket(ENV['bucket'])
Yajl::Parser.parse(STDIN) do |set|
  set['keys'] && set['keys'].each {|key| p bucket.delete(key) }
end
