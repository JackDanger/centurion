require 'spec_helper'

describe Centurion::Collector do

  let(:project_root) { File.expand_path '../../../', __FILE__ }
  let(:commit_range) { ['HEAD^', 'HEAD'] }
  let(:options) {{
    :project_root => project_root,
    :commit_range => commit_range
  }}
  let(:project_name) { 'centurion' }

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
    before  { collector.stub(:meter_key).and_return('meter-key') }
    before  { collector.stub(:flog_key).and_return('flog-key')   }
    subject { collector.meter }

    it 'creates new flog record' do
      expect { subject }.to change {
        collector.flogs_bucket.exists? 'flog-key'
      }
    end

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
  end
end
