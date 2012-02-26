$:.unshift File.expand_path '..', __FILE__
require 'centurion'
require 'fake_riak'
require 'grit_commit_equality'

module Centurion
  TestRepo = ::File.expand_path '../test_repo', __FILE__
  def self.test_project
    Project.new :project_root => TestRepo
  end
  unless ::File.exists? TestRepo
    %x{tar xzf #{TestRepo}.tgz spec/}
  end
  # Every commit and file from the test_repo git history
  # (excluding the initial commit)
  TestRepoCommits = {
     '969cfaa2caad3520bc83a21d05cb295b1191fe6f' => ['rowan.rb'],
     '7a0f9310adc672d2f16ea1b800780c49130ccea6' => ['rowan.rb', 'cleese.rb'],
     '8ad3ea51e4993f687a38332c01e52d1072f5c47b' => ['cleese.rb'],
     '702089b0b487e59d85e3a39d56eb0fdba85dbf2c' => ['cleese.rb', 'lithgow.rb'],
     'c96fc1175a33ee5d398e40d7cfed6fc702188cbd' => ['cleese.rb', 'lithgow.rb']
     }.inject({}) {|hash, (sha, files)|
       commit = test_project.commits.detect {|c| c.sha == sha }
       hash[commit] = files.map do |filename|
         File.new :name   => filename,
                  :commit => commit
       end
       hash
     }
end

RSpec.configure do |config|
  config.before :all do
    FakeRiak.install
  end

  config.after :each do
    FakeRiak.cleanup
  end
end
