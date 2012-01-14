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
      each_commit do |commit|
        puts "Collecting #{commit} in #{project_name}"
        files.each_with_index do |file, idx|
          Flog.new(file, commit).meter do |data|
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

    def each_commit
      first, final = @commit_range
      if 'start' == first
        commit = @repo.commit final
        until (commit = commit.parents.first) && commit.parents.blank?
          first = commit.sha
        end
      end
      @repo.commits_between(first, final).each do |commit|
        yield commit
      end
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
