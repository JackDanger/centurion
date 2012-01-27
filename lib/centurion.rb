require 'grit'
require 'riak'

module Centurion
  def self.db
    @db ||= Riak::Client.new
  end

  autoload :Persistence, 'centurion/persistence'
  autoload :Project,     'centurion/project'
  autoload :Commission,  'centurion/commission'
  autoload :Flog,        'centurion/flog'

  Dir.glob(File.expand_path '../centurion/**/*.rb', __FILE__).each do |rb|
    require rb
  end
end

