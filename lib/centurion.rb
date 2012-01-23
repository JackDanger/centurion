require 'grit'
require 'riak'

module Centurion
  def self.db
    @db ||= Riak::Client.new
  end

  autoload :BucketList, 'centurion/bucket_list'
  autoload :Project,    'centurion/project'
  autoload :Collector,  'centurion/collector'
  autoload :Flog,       'centurion/flog'

end

