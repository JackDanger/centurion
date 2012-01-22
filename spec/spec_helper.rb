$:.unshift File.expand_path '..', __FILE__
require 'centurion'
require 'fake_riak'

module Centurion
  TestRepo = File.expand_path '../test_repo', __FILE__
  unless File.exists? TestRepo
    %x{tar xzf #{TestRepo}.tgz -C spec/}
  end
end

RSpec.configure do |config|
  config.before do
    FakeRiak.install
    Centurion::Collector.any_instance.stub(:log)
  end

  config.after do
    FakeRiak.cleanup
  end
end
