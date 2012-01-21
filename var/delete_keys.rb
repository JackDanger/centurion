require 'rubygems'
gem 'yajl-ruby'
require 'riak'
require 'yajl'
riak = Riak::Client.new
bucket = riak.bucket('centurion')
Yajl::Parser.parse(STDIN) do |set|
  set['keys'] && set['keys'].each {|key| puts bucket.delete(key) }
end
