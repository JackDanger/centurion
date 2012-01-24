require 'spec_helper'

describe Centurion::Project do

  let(:project_root)      { Centurion::TestRepo                 }
  let(:project)           { Centurion::Project.new project_root }
  let(:commits_and_files) { Centurion::TestRepoCommits          }


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

    let(:run_time) { Time.now }
    before  {
      project.stub(:run_time).and_return(run_time)
      project.stub(:run_key).and_return('run-key')
    }

    subject { project.run! }

    it {
      expect { subject }.to change {
        project.commits_bucket.keys(:reload => true).size
      }.from(0).to(project.commits.size)
    }

    it 'sets processedAt' do
      subject
      project.commits {|commit|
        project.commits_bucket.
                get(commit.sha).
                data[:processedAt].should == run_time.to_i
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

    it 'updates a project that has been run before'

    it 'calculates each commit' do
      expect { subject }.to change {
        project.commits_bucket.keys.size
      }.from(0).to(commits_and_files.size)
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
