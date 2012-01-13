require 'grit'
module Centurion
  class Collector

    attr_reader :project_root, :project_name,
                :repo, :bucket

    def initialize options
      p options
      @project_root = options[:project_root]
      @commit_range = options[:commit_range]
      @repo  = Grit::Repo.new project_root
      @project_name = File.basename project_root
      @bucket = Centurion.db.bucket(project_name)
    end

    def meter
      each_commit do |ref|
        puts "Collecting #{ref} in #{project_name}"
        each_file do |file, idx|
          Flog.new(file, commit_data_for(ref)).meter do |data|
            insert data
          end
          puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{project_root}\//,'')}"
        end
      end
    end

    def insert data
      key = "#{data[:sha]}:#{data[:file]}:#{data[:method]}"
      key.gsub!(/[\/\\\^\[\]\{\}\(\)]+/, '-')
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

    def each_commit
      @repo.commits(@commit_range).each do |commit|
        yield commit
      end
    end

    def each_file
      found = Dir.glob File.join(project_root, '**/*.rb')
      warn "No Ruby source files found in #{project_root}!" if found.empty?
      found.each_with_index do |file, idx|
        path = file.sub(/^#{project_root}\//, '')
        yield path, idx
      end
    end
  end
end
