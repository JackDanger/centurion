$:.unshift File.expand_path '..', __FILE__
require 'centurion'
require 'fake_riak'

RSpec.configure do |config|
  config.before do
    FakeRiak.install
  end

  config.after do
    FakeRiak.cleanup
  end
end
