require 'flog'
require 'mongo'
require 'centurion/flog'

class Centurion

  attr_accessor :repo, :store

  def initialize(project_root)
    @project_root = project_root
    @repo  = Grit::Repo.new(project_root)
    @store = Mongo::Connection.new.db("centurion")
  end

  def meter(ref)
    files.each_with_index do |file, idx|
      Flog.new(file, commit_data_for(ref)).meter
      puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{project_root}\//,'')}"
    end
  end

  def commit_data_for ref
    commit = repo.commit(ref)
    {
      :sha    => commit.sha,
      :time   => commit.date.to_i,
      :author => commit.author
    }
  end

  def files
    @files ||= Dir.glob File.join(root_path, '**/*.rb')
  end

  def self.insert data
    Store.insert data
  end
end
