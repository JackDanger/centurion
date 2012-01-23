$:.unshift File.expand_path '..', __FILE__
require 'centurion'
require 'fake_riak'
require 'grit_commit_equality'

module Centurion
  TestRepo = File.expand_path '../test_repo', __FILE__
  unless File.exists? TestRepo
    %x{tar xzf #{TestRepo}.tgz spec/}
  end
  # Every commit and file from the test_repo git history
  # (excluding the initial commit)
  repo = Grit::Repo.new TestRepo
  TestRepoCommits = {
     '7a0f9310adc672d2f16ea1b800780c49130ccea6' => ['rowan.rb', 'cleese.rb'],
     '8ad3ea51e4993f687a38332c01e52d1072f5c47b' => ['cleese.rb'],
     '702089b0b487e59d85e3a39d56eb0fdba85dbf2c' => ['cleese.rb', 'lithgow.rb']
     }.inject({}) {|hash, (sha, files)|
       commit = repo.commits.detect {|c| c.sha == sha }
       hash[commit] = files
       hash
     }
end

RSpec.configure do |config|
  config.before :each do
    FakeRiak.install
    Centurion::Collector.any_instance.stub(:log)
  end

  config.after :each do
    FakeRiak.cleanup
  end
end
