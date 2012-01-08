require 'grit'
require 'mongo'
require 'centurion/flog'

class Centurion

  attr_accessor :project_root, :repo, :store

  def initialize project_root
    @project_root = project_root
    @repo  = Grit::Repo.new project_root
    project_name = File.basename project_root
    @store = Mongo::Connection.new.db("centurion").collection(project_name)
  end

  def meter ref
    files.each_with_index do |file, idx|
      Flog.new(file, commit_data_for(ref)).meter do |data|
        store.insert data
      end
      puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{project_root}\//,'')}"
    end
  end

  def commit_data_for ref
    commit = repo.commit ref
    {
      :sha    => commit.sha,
      :time   => commit.date.to_i,
      :author => commit.author
    }
  end

  def files
    @files ||= begin
      found = Dir.glob File.join(project_root, '**/*.rb')
      warn "No Ruby source files found in #{project_root}!" if found.empty?
      found
    end
  end
end
