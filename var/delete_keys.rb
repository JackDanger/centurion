require 'rubygems'
gem 'yajl-ruby'
require 'riak'
require 'yajl'
riak = Riak::Client.new
bucket = riak.bucket(ENV['bucket'])
bucket.keys do |set|
  p set
  set.each {|key| p bucket.delete(key) }
end
