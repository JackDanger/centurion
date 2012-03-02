require 'spec_helper'

describe Centurion::Project do

  let(:project_root)      { Centurion::TestRepo                 }
	let(:project)           { Centurion.test_project              }
  let(:commits_and_files) { Centurion::TestRepoCommits          }
  let(:frozen_moment)     { project.run_at                      }

  def project_doc
    key = project.project_key project
    project.projects_bucket.get key
  end

  def for_each_commit
    project.commits.map do |commit|
      key = commit.key
      bucket = project.commits_bucket
      yield bucket, key
    end
  end

  describe '#root' do
    subject { project.root }
    it { should == project_root }
  end

  describe '#name' do
    subject { project.name }
    it { should == 'test_repo' }
  end

  describe '#commits' do
    subject { project.commits }
    it { should == Grit::Repo.new(project_root).commits.reverse }
  end

  describe 'project analysis' do

    before {
      project.stub(:run_key).and_return('run-key')
    }

    subject { project.run! }

    it {
      expect { subject }.to change {
        for_each_commit {|bucket, key| bucket.exists? key }
      }.from([false]*5).
        to(  [true ]*5) }

    it 'sets processedAt' do
      subject
      for_each_commit {|bucket, key|
        bucket.
          get(key).
          data['processedAt'].should == frozen_moment
      }
    end

    it 'records the commits that are processed' do
      project.runs_bucket.exists?('run-key').should be_false
      subject
      doc = project.runs_bucket.get('run-key')
      doc.data['commits'].should == project.commits.size
      doc.data['start'].should   == project.commits.last.sha
      doc.data['end'].should     == project.commits.first.sha
      doc.data['duration'].should be_within(2.5).of(2.8)
    end

    it 'meters just new commits' do
      until project.commits_bucket.keys(:reload => true).empty?
        sleep 0.1
      end
      project.commits.first.update({}) # pretend this was metered already
      expect { subject }.to change {
        project.commits_bucket.keys(:reload => true).size
      }.by(project.commits.size - 1)
    end

    it 'updates project record' do
      expect { subject }.to change {
        project.projects_bucket.exists? project.name
      }
    end

    it 'stores a cache of all commit keys' do
      project.commit_cache.should be_nil
      subject
      project.commit_cache.data['shas'].should == project.commits.map(&:sha)
    end
  end

  describe '#commits_bucket' do
    subject { project.commits_bucket.name }
    it { should == "test_repo_commits" }
  end

  describe '#authors_bucket' do
    subject { project.authors_bucket.name }
    it { should == "test_repo_authors" }
  end

  describe '#files_bucket' do
    subject { project.files_bucket.name }
    it { should == "test_repo_files" }
  end

  describe '#runs_bucket' do
    subject { project.runs_bucket.name }
    it { should == "runs" }
  end
end
