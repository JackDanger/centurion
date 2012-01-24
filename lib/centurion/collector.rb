require 'grit'
module Centurion
  class Collector

    attr_reader :project, :project,
                :repo, :commit

    def initialize options
      @project = options[:project]
      @repo    = project.repo
    end

    def meter commit
      log "Collecting #{commit} in #{project.name}"
      files = files_for commit
      files.each_with_index do |file, idx|
        meter_file file, commit
        log "processed #{idx+1}/#{files.size} - #{file}"
      end
    end

    def meter_file filename, commit
      file_flog = {}
      Centurion::Flog.new(
        file_contents_for(commit, filename),
        filename,
        commit
      ).meter do |method_flog|
        file_flog = method_flog.slice :average, :total
        project.update_method commit, filename, method_flog
      end
      project.update_file commit, filename, file_flog
    end

    protected

      def files_for commit
        find_tree = "git ls-tree -r #{commit.tree.id} | awk '{print $4}' | egrep \\.rb$"
        file_list = `cd #{project.root} && #{find_tree}`
        files = file_list.split("\n")
        warn "No Ruby source files found in #{project.root}! (at #{commit.sha})" if files.empty?
        files
      end

      def file_contents_for commit, filename
        `cd #{project.root} && git show #{commit.sha}:#{filename}`
      end

      def log string
        puts string
      end
  end
end
