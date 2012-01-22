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

      it 'calculates files from the previous commit' do
        # subject.should == 3
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
