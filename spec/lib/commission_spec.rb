require 'spec_helper'

describe Centurion::Commission do

  let(:project_root)      { Centurion::TestRepo                 }
  let(:project)           { Centurion::Project.new project_root }
  let(:commit)            { project.repo.commits.first          }
  let(:commits_and_files) { Centurion::TestRepoCommits          }
  let(:project_name)      { 'test_repo'                         }
  let(:frozen_moment)     { Time.now                            }

  let(:commission) {
    Centurion::Commission.new :project => project,
                              :commit  => commit
  }

  describe '#repo' do
    subject { commission.repo.working_dir }
    it { should == project_root }
  end

  describe '#project' do
    subject { commission.project }
    it { should == project }
  end

  describe '#commit' do
    subject { commission.commit }
    it { should == commit }
  end

  describe '#run!' do
    Centurion::TestRepoCommits.each do |test_commit, files|
      context "for #{test_commit} => #{files.inspect}" do
        let(:commit) { test_commit }
        subject { commission.run! }

        it 'calculates all (and only) files from the given commit' do
          files.each do |file|
            commission.should_receive(:meter_file).
                       with(file).
                       once
          end
          subject
        end

        it 'calculates the total score for the commit'
      end
    end
  end

  describe '#meter_file' do

    let(:commit)   { commits_and_files.keys.first      }
    let(:file)     { commits_and_files.values.first[0] }
    let(:file_key) { project.file_key commit, file     }
    let(:flog_scores) {{
      :total   => 5.5,
      :average => 2.3,
      :method  => 'File#open'
    }}

    subject { commission.meter_file file }

    it 'creates new file record' do
      expect { subject }.to change {
        project.files_bucket.exists? file_key
      }
    end

    context 'data[]' do
      subject {
        commission.meter_file file
        project.files_bucket.get(file_key).data[attribute.to_s]
      }

      context 'sha' do
        let(:attribute) { :sha }
        it { should == commit.sha }
      end

      context 'processedAt' do
        let(:attribute) { :processedAt }
        it { should == frozen_moment.to_i }
      end

      context 'flog' do
        let(:attribute) { :flog }
        before {
          Centurion::Flog.any_instance.
                          stub(:meter).
                          and_yield(flog_scores)
        }
        it { should == 5.5 }
      end

      context 'flogAverage' do
        let(:attribute) { :flogAverage }
        before {
          Centurion::Flog.any_instance.
                          stub(:meter).
                          and_yield(flog_scores)
        }
        it { should == 2.3 }
      end

      context 'flogDelta' do
        let(:attribute) { :flogDelta }
        before {
          Centurion::Flog.any_instance.
                          stub(:meter).
                          and_yield(flog_scores)
          commits_and_files.each {|commit, files|
            files.each {|file|
              key = project.file_key(commit, file)
              old = project.files_bucket.new(key)
              old.data = {:flog => 15}
              old.store
            }
          }
        }
        it { should == -9.5 }
      end
    end
  end
end
