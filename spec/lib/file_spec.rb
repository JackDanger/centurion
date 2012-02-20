require 'spec_helper'

describe Centurion::File do

	let(:project) { Centurion::TestProject  }
	let(:commits_and_files) { Centurion::TestRepoCommits  }
  let(:previous_sha)      { "702089b0b487e59d85e3a39d56eb0fdba85dbf2c" }
  let(:previous_commit)   { commits_and_files.map(&:first).detect {|c| c.sha == previous_sha } }
  let(:commit)            { commits_and_files.map(&:first).detect {|c| c.sha == sha } } 
  let(:sha)               { "c96fc1175a33ee5d398e40d7cfed6fc702188cbd" }
  let(:file)              { commits_and_files.map(&:last).last[0] } # cleese.rb

	describe 'meter' do

		subject { file.meter }

		it 'creates a record' do
			expect { subject }.to change {
				project.files_bucket.exists?(file.key)
		  }
		end

		it 'calculates a score' do
			subject
			document = project.files_bucket.get_or_new(file.key)
			document.data['flog'].should be_within(0.1).of(3.6)
		end

		it 'calculated a score delta' do
			previous_commit.meter
			subject
			document = project.files_bucket.get_or_new(file.key)
			document.data['flogDelta'].should be_within(0.1).of(1.2)
		end
	end
end
