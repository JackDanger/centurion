require 'spec_helper'

describe Centurion::Flog do

  let(:file)   { __FILE__ }
  let(:repo)   { Grit::Repo.new(File.expand_path '../../../', __FILE__) }
  let(:commit) { repo.commits.first }
  let(:flog) { Centurion::Flog.new(file, commit) }

  describe '#meter' do
    it 'yields flog-specific data' do
      flog.meter do |measurements|
        measurements[:file      ] .should == file
        measurements[:sha       ] .should == commit.sha
        measurements[:total     ] .should be_a(Float)
        measurements[:average   ] .should be_a(Float)
        measurements[:score     ] .should be_a(Float)
        measurements[:time      ] .should be_a(Fixnum)
        measurements[:method    ] .should be_a(String)
        measurements[:author    ] .should be_a(String)
        measurements[:parent    ] .should be_a(String)
        measurements[:call_list ] .should be_a(Hash)
      end
    end
  end
end
