require 'grit'
require 'riak'

module Centurion
  def self.db
    @db ||= Riak::Client.new
  end

  Dir.glob(::File.expand_path '../centurion/**/*.rb', __FILE__).each do |source|

    klass = ::File.basename(source).sub(/^./, &:upcase).chomp('.rb')
    autoload klass, source
  end
end

def silently
  old_error, $stderr = $stderr, StringIO.new
    yield
ensure
  $stderr = old_error
end

silently do
  module Grit
    Commit = Centurion::Commit
    Repo = Centurion::Repo
  end
end

