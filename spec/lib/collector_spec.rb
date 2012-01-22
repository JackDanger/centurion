require 'spec_helper'

describe Centurion::Collector do

  let(:project_root) { Centurion::TestRepo }
  let(:commit_range) { ['HEAD^', 'HEAD'] }
  let(:options) {{
    :project_root => project_root,
    :commit_range => commit_range
  }}
  let(:project_name) { 'test_repo' }

  let(:collector) { Centurion::Collector.new options }
  # Every commit and file from the test_repo git history
  let(:commits_and_files) {
    {
     '7a0f9310adc672d2f16ea1b800780c49130ccea6' => ['rowan.rb', 'cleese.rb'],
     '8ad3ea51e4993f687a38332c01e52d1072f5c47b' => ['cleese.rb'],
     '702089b0b487e59d85e3a39d56eb0fdba85dbf2c' => ['cleese.rb', 'lithgow.rb']
     }.inject({}) {|hash, (sha, files)|
       commit = collector.repo.commits.detect {|c| c.sha == sha }
       # files = files.map {|f| "#{Centurion::TestRepo}/#{f}" }
       hash[commit] = files
       hash
     }
   }


  describe '#repo' do
    subject { collector.repo.working_dir }
    it { should == project_root }
  end

  describe '#project_name' do
    subject { collector.project_name }
    it { should == project_name }
  end

  describe '#meter' do

    subject { collector.meter }

    before  { collector.stub(:meter_key).and_return('meter-key') }
    before  { collector.stub(:flog_key).and_return('flog-key')   }

    it 'creates new meter record' do
      expect { subject }.to change {
        collector.meters_bucket.exists? 'meter-key'
      }
    end

    it 'updates project record' do
      expect { subject }.to change {
        collector.projects_bucket.exists? project_name
      }
    end

    context 'across multiple commits' do
      let(:commit_range) { ['HEAD^^^', 'HEAD'] }

      it 'calculates each commit' do
        commits_and_files.each do |commit, files|
          collector.should_receive(:meter_commit).
                    with(commit).
                    once
        end
        subject
      end

      it 'calculates all (and only) files from the given commit' do
        commits_and_files.each do |commit, files|
          files.each do |file|
            collector.should_receive(:meter_file).
                      with(file, commit).
                      once
          end
        end
        subject
      end
    end
  end

  describe '#meter_commit' do

    let(:commit) { collector.repo.commits.first }
    let(:files)  {
      Dir.glob(project_root + '/**/*.rb').
          map {|f| f.sub(/^#{project_root}\//, '') }
    }

    subject { collector.meter_commit commit }

    it 'measures each file' do
      files.each do |file|
        collector.should_receive(:meter_file).
                  with(file, commit).
                  once
      end
      subject
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
