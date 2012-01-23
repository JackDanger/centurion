require 'spec_helper'

describe Centurion::Project do

  let(:project_root) { Centurion::TestRepo                 }
  let(:project)      { Centurion::Project.new project_root }

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
        batch_count = project.commits.size / batch_size
        catcher = Object.new
        catcher.should_receive(:batch_received).exactly(batch_count).times
        project.commits(batch_size) do |batch|
          catcher.batch_received
          batch.size.should == batch_size
        end
      end
    end
  end

  describe '#update_commit_list' do
    subject { project.update_commit_list }
    it {
      expect { subject }.to change {
        project.commits_bucket.keys(:reload => true).size
      }.from(0).to(project.commits.size)
    }
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
end
