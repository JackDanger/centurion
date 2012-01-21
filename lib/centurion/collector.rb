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
      finish = Time.now
      update_project  start, finish
      record_metering start, finish
    end

    def update_project start, finish
      store_in projects_bucket, project_name, :updated_at => finish,
                                              :last_duration => finish - start
    end

    def record_metering start, finish
      store_in meters_bucket, meter_key(finish), :duration => finish - start
    end

    def insert_flog data
      store_in flogs_bucket, flog_key(data), data
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

    def flog_key data
      sha    = data[:sha]
      file   = digest data[:file]
      method = digest data[:method]
      "#{sha}:#{file}:#{method}"
    end

    def meter_key finish
      "#{project_name}:#{finish.to_i}"
    end

    def flogs_bucket
      Centurion.db.bucket "#{project_name}_flogs"
    end

    def meters_bucket
      Centurion.db.bucket "#{project_name}_meters"
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
