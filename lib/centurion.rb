require 'grit'
require 'riak'

module Centurion
  def self.db
    @db ||= Riak::Client.new
  end
end
require 'centurion/flog'
require 'centurion/project'
require 'centurion/collector'
