require 'grit'
module Centurion
  class Collector

    attr_reader :project_root, :project_name,
                :repo, :commit_range

    def initialize options
      @project_root = options[:project_root]
      @commit_range = options[:commit_range]
      @repo  = Grit::Repo.new project_root
      @project_name = File.basename project_root
    end

    def meter
      start = Time.now
      each_commit do |commit|
        meter_commit commit
      end
      finish = Time.now
      update_project  start, finish
      record_metering start, finish
    end

    def meter_commit commit
      log "Collecting #{commit} in #{project_name}"
      files = files_for commit
      files.each_with_index do |file, idx|
        meter_file file, commit
        log "processed #{idx+1}/#{files.size} - #{file}"
      end
      #updated_index commit
    end

    def meter_file filename, commit
      Flog.new(
        file_contents_for(commit, filename),
        filename,
        commit
      ).meter do |data|
        insert_flog data
      end
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

    protected

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
        file   = digest data[:file].sub(/^#{project_root}\//, '')
        method = digest data[:method]
        "#{sha}:#{file}:#{method}"
      end

      def meter_key finish
        "#{project_name}:#{finish.to_i}"
      end

      def files_for commit
        find_tree = "git ls-tree -r #{commit.tree.id} | awk '{print $4}' | egrep \\.rb$"
        file_list = `cd #{project_root} && #{find_tree}`
        files = file_list.split("\n")
        warn "No Ruby source files found in #{project_root}!" if files.empty?
        files
      end

      def file_contents_for commit, filename
        `cd #{project_root} && git show #{commit.sha}:#{filename}`
      end

      def each_commit
        first, final = commit_range
        # You can provide 'start' as the beginning of your commit range
        # This will process the entire project history
        if 'start' == first
          commit = repo.commit final
          until (commit = commit.parents.first) && commit.parents.blank?
            first = commit.sha
          end
        end

        commits = Grit::Commit.find_all repo, "#{first}..#{final}"

        commits.each do |commit|
          yield commit
        end
      end

      def log string
        puts string
      end
    end
end
