require 'spec_helper'

describe Centurion::Commit do

  let(:project_root)      { Centurion::TestRepo                 }
  let(:project)           { Centurion::Project.new project_root }
  let(:commits_and_files) { Centurion::TestRepoCommits          }
  let(:project_name)      { 'test_repo'                         }
  let(:frozen_moment)     { project.run_at                      }
  let(:commit)            { project.commits.first               }

  describe '#repo' do
    subject { commit.repo.working_dir }
    it { should == project_root }
  end

  describe '#project' do
    subject { commit.project }
    it { should == project }
  end

  describe '#meter' do
    let(:file) { commits_and_files.detect { |c,f|
                        c == commit
                    }.last[0]                          }
    let(:filename) { file.name                         }
    let(:file_key) { file.key                          }
    let(:flog_scores) {{
      :total   => 5.5,
      :average => 2.3,
      :method  => 'File#open'
    }}

    Centurion::TestRepoCommits.each do |test_commit, files|
      context "for #{test_commit.sha} => #{files.map(&:name).inspect}" do
        let(:commit) { test_commit }
        subject { commit.meter }

        it 'calculates all (and only) files from the given commit' do
          # files.each do |file|
          #   file.should_receive(:meter).once
          # end
          expect { subject }.to change {
            project.files_bucket.keys(:reload => true).size
          }.by files.size
        end

        it 'calculates the total score for the commit'

        it 'creates new file record' do
          expect { subject }.to change {
            project.files_bucket.exists? files.first.key
          }
        end
      end
    end
    context 'data[]' do
      subject {
        commit.meter
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
              old = project.files_bucket.new(file.key)
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
