require 'spec_helper'

describe Centurion::Project do

  let(:project_root)      { Centurion::TestRepo                 }
  let(:project)           { Centurion::Project.new project_root }
  let(:commits_and_files) { Centurion::TestRepoCommits          }
  let(:frozen_moment)     { Time.now.to_i                       }

  before { project.stub(:run_at).and_return frozen_moment }

  def project_doc
    key = project.project_key project
    project.projects_bucket.get key
  end

  def for_each_commit
    project.commits.map do |commit|
      key = project.commit_key commit
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
    # try different batch sizes, ensure batching works
    [1,2,3,4,5].each {|batch_size|
      subject { project.commits batch_size }
      it { should == Grit::Repo.new(project_root).commits }
    }

    context 'one batch at a time' do
      let(:batch_size) { 2 }
      it 'yields each batch' do
        catcher = Object.new
        catcher.should_receive(:batch_received).
                exactly(project.commits.size).times
        project.commits(batch_size) do |commit|
          catcher.batch_received
        end
      end
    end
  end

  describe '#run!' do

    before {
      project.stub(:run_key).and_return('run-key')
    }

    subject { project.run! }

    it {
      expect { subject }.to change {
        for_each_commit {|bucket, key| bucket.exists? key }
      }.from([false]*4).
        to(  [true ]*4)
    }

    it 'sets processedAt' do
      subject
      for_each_commit {|bucket, key|
        bucket.
          get(key).
          data['processedAt'].should == frozen_moment
      }
    end

    it 'creates new run record' do
      expect { subject }.to change {
        project.runs_bucket.exists? 'run-key'
      }
    end

    it 'updates project record' do
      expect { subject }.to change {
        project.projects_bucket.exists? project.name
      }
    end

    it 'updates a project that has been run before' do
      commit = project.commits.first
      commit.update({})
      commit.
        should_not_receive(:meter)
      project.commits.last.
        should_receive(:meter)
      subject
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

  describe '#methods_bucket' do
    subject { project.methods_bucket.name }
    it { should == "test_repo_methods" }
  end

  describe '#runs_bucket' do
    subject { project.runs_bucket.name }
    it { should == "runs" }
  end
end
