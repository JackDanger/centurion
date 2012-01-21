require 'grit'
module Centurion
  class Collector

    attr_reader :project_root, :project_name, :repo

    def initialize options
      @project_root = options[:project_root]
      @commit_range = options[:commit_range]
      @repo  = Grit::Repo.new project_root
      @project_name = File.basename project_root
    end

    def meter
      start = Time.now
      each_commit do |commit|
        puts "Collecting #{commit} in #{project_name}"
        files.each_with_index do |file, idx|
          Flog.new(file, commit).meter do |data|
            insert_flog data
          end
          puts "processed #{idx+1}/#{files.size} - #{file.sub(/^#{project_root}\//,'')}"
        end
        #updated_index commit
      end
      update_project start, Time.now
    end

    def update_project start, finish
      store_in projects_bucket,
               project_name,
               :updated_at => finish,
               :last_duration => finish - start
      store_in meterings_bucket,
               "#{project_name}:#{finish.to_i}",
               :duration => finish - start
    end

    def insert_flog data
      sha    = data[:sha]
      file   = digest data[:file]
      method = digest data[:method]

      key = "#{sha}:#{file}:#{method}"

      store_in flog_bucket, key, data
    end

    def store_in bucket, key, data
      doc = bucket.get_or_new key
      doc.data = data
      doc.content_type = 'application/json'
      doc.store
    end

    def digest string
      Digest::SHA1.hexdigest(string)[0..6]
    end

    def flog_bucket
      Centurion.db.bucket "#{project_name}_flog"
    end

    def meterings_bucket
      Centurion.db.bucket "meterings"
    end

    def projects_bucket
      Centurion.db.bucket "projects"
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
