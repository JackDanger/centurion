require 'spec_helper'

describe Centurion::Commit do

  let(:project_root)      { Centurion::TestRepo                 }
  let(:project)           { Centurion.test_project              }
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
    }}

    Centurion::TestRepoCommits.each do |test_commit, files|
      context "for #{test_commit.sha} => #{files.map(&:name).inspect}" do
        let(:commit) { test_commit }
        subject { commit.meter }

        it 'calculates all (and only) files from the given commit' do
          expect { subject }.to change {
            sleep 0.2
            project.files_bucket.keys(:reload => true).size
          }.by files.size
        end

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
    end
  end
end
