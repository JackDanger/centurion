require 'grit'
module Centurion
  class Collector

    attr_reader :project, :project,
                :repo, :commit_range

    def initialize options
      @project = Centurion::Project.new options[:project]
      @project.name = File.basename project.name
      @repo = project.repo
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
      log "Collecting #{commit} in #{project.name}"
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

    protected

      def update_project start, finish
        store_in projects_bucket, project.name, :updated_at => finish,
                                                :last_duration => finish - start
      end

      def record_metering start, finish
        store_in meters_bucket, meter_key(finish), :duration => finish - start
      end

      def insert_flog data
        store_in flogs_bucket, flog_key(data), data
      end

      def flog_key data
        sha    = data[:sha]
        file   = digest data[:file].sub(/^#{project.root}\//, '')
        method = digest data[:method]
        "#{sha}:#{file}:#{method}"
      end

      def meter_key finish
        "#{project.name}:#{finish.to_i}"
      end

      def files_for commit
        find_tree = "git ls-tree -r #{commit.tree.id} | awk '{print $4}' | egrep \\.rb$"
        file_list = `cd #{project.root} && #{find_tree}`
        files = file_list.split("\n")
        warn "No Ruby source files found in #{project.root}!" if files.empty?
        files
      end

      def file_contents_for commit, filename
        `cd #{project.root} && git show #{commit.sha}:#{filename}`
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
