require 'grit'
module Centurion
  class Collector

    attr_reader :project_root, :repo, :bucket

    def initialize project_root
      @project_root = project_root
      @repo  = Grit::Repo.new project_root
      project_name = File.basename project_root
      @bucket = Centurion.db.bucket(project_name)
    end

    def meter ref
      files.each_with_index do |file, idx|
        Flog.new(file, commit_data_for(ref)).meter do |data|
          insert data
        end
        puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{project_root}\//,'')}"
      end
    end

    def insert data
      key = "#{data[:sha]}:#{data[:file]}:#{data[:method]}"
      doc = bucket.get_or_new key
      doc.data = data
      doc.content_type = 'application/json'
      doc.store
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
        found.map {|file| file.sub(/^#{project_root}\//, '') }
      end
    end
  end
end
