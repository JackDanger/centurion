require 'spec_helper'

describe Centurion::Flog do

  let(:file)   { __FILE__                          }
  let(:source) { File.read(__FILE__)               }
  let(:root)   { Centurion::TestRepo               }
  let(:repo)   { Grit::Repo.new(root)              }
  let(:commit) { repo.commits.first                }
  let(:flog)   { Centurion::Flog.new(source, file) }

  describe '#meter' do
    it 'yields flog-specific data' do
      flog.meter do |measurements|
        measurements[:total     ] .should be_a(Float)
        measurements[:average   ] .should be_a(Float)
        measurements[:score     ] .should be_a(Float)
        measurements[:method    ] .should be_a(String)
        measurements[:call_list ] .should be_a(Hash)
      end
    end
  end
end
