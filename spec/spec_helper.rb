$:.unshift File.expand_path '..', __FILE__
require 'centurion'
require 'fake_riak'

RSpec.configure do |config|
  config.before do
    FakeRiak.install
    Centurion::Collector.any_instance.stub(:log)
  end

  config.after do
    FakeRiak.cleanup
  end
end
