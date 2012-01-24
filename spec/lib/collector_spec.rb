require 'spec_helper'

describe Centurion::Collector do

  let(:project_root)      { Centurion::TestRepo                 }
  let(:project)           { Centurion::Project.new project_root }
  let(:commit_range)      { ['HEAD^', 'HEAD']                   }
  let(:commits_and_files) { Centurion::TestRepoCommits          }
  let(:project_name)      { 'test_repo'                         }
  let(:frozen_moment)     { Time.now                            }

  let(:collector) { Centurion::Collector.new :project => project }


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

    let(:file)     { 'cleese.rb'                   }
    let(:commit)   { collector.repo.commits.first  }
    let(:file_key) { project.file_key commit, file }

    subject { collector.meter_file file, commit }

    it 'creates new file record' do
      expect { subject }.to change {
        project.files_bucket.exists? file_key
      }
    end

    context 'data[]' do
      subject {
        collector.meter_file file, commit
        project.files_bucket.get(file_key).data[attribute.to_s]
      }

      context 'sha' do
        let(:attribute) { :sha }
        it { should == commit.sha }
      end

      context 'author' do
        let(:attribute) { :author }
        it { should == commit.author }
      end

      context 'comment' do
        let(:attribute) { :comment }
        it { should == commit.message }
      end

      context 'processedAt' do
        let(:attribute) { :processedAt }
        it { should == frozen_moment }
      end

      context 'date' do
        let(:attribute) { :date }
        it { should == commit.date.to_i }
      end

      context 'parent' do
        let(:attribute) { :parent }
        it { should == commit.parents.first.sha }
      end

      context 'score' do
        let(:attribute) { :score }
        before {
          Centurion::Flog.any_instance.
                          stub(:meter).
                          and_yield({:total => 5.5})
        }
        it { should == 5.5 }
      end

      context 'scoreDelta' do
        let(:attribute) { :scoreDelta }
        before {
          Flog.any_instance.stub(:meter).and_yield({:score => 5.5})
          parent = project.commits_bucket.get_or_new(commit.parents.first.sha)
          parent.data = {:score => 15}
          parent.store
        }
        it { should == -9.5 }
      end
    end
  end
end
