require 'spec_helper'

describe Centurion::Collector do

  let(:project_root)      { Centurion::TestRepo        }
  let(:commit_range)      { ['HEAD^', 'HEAD']          }
  let(:commits_and_files) { Centurion::TestRepoCommits }
  let(:project_name)      { 'test_repo'                }
  let(:options) {{
    :project_root => project_root,
    :commit_range => commit_range
  }}

  let(:collector) { Centurion::Collector.new options }

  describe '#repo' do
    subject { collector.repo.working_dir }
    it { should == project_root }
  end

  describe '#project_name' do
    subject { collector.project_name }
    it { should == project_name }
  end


  describe '#meter_commit' do

    let(:commit) { collector.repo.commits.first }
    let(:files)  {
      Dir.glob(project_root + '/**/*.rb').
          map {|f| f.sub(/^#{project_root}\//, '') }
    }

    Centurion::TestRepoCommits.each do |commit, files|
      context "for #{commit} => #{files.inspect}" do
        subject { collector.meter_commit commit }

        it 'calculates all (and only) files from the given commit' do
          commits_and_files.each do |commit, files|
            files.each do |file|
              project.should_receive(:meter_file).
                        with(file, commit).
                        once
            end
          end
          subject
        end
      end
    end
  end

  describe '#meter_file' do

    let(:file)   { 'cleese.rb' }
    let(:commit) { collector.repo.commits.first }

    subject { collector.meter_file file, commit }

    before  { collector.stub(:meter_key).and_return('meter-key') }
    before  { collector.stub(:flog_key).and_return('flog-key')   }

    it 'creates new flog record' do
      expect { subject }.to change {
        collector.flogs_bucket.exists? 'flog-key'
      }
    end

  end
end
