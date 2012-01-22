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
  let(:commits_and_files) {
    {
     '969cfaa2caad3520bc83a21d05cb295b1191fe6f' => ['rowan.rb'],
     'a5024f790f22f02ddeff14e374b5ed11cca57946' => ['rowan.rb', 'cleese.rb'],
     '0313b90b681947d424c61b7e9a75bf5a31aa6f2d' => ['cleese.rb']
     }.inject({}) {|hash, (sha, files)|
       commit = collector.repo.commits.detect {|c| c.sha == sha }
       files = files.map {|f| "#{Centurion::TestRepo}/#{f}" }
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
      let(:commit_range) { ['HEAD^^', 'HEAD'] }

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
    let(:files)  { Dir.glob(project_root + '/**/*.rb') }

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

    let(:file)   { __FILE__ }
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
