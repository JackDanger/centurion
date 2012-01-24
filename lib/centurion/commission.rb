require 'grit'
module Centurion
  class Commission

    attr_reader :project, :repo,
                :commit,  :sha,
                :totals,  :averages

    def initialize options
      @project = options[:project]
      @repo    = project.repo
      @commit  = options[:commit]
      @sha     = commit.sha
      @totals, @averages = Array.new, Array.new
    end

    def run!
      log "Collecting #{sha} in #{project.name}"
      files.each_with_index do |file, idx|
        meter_file file
        log "processed #{idx+1}/#{files.size} - #{file}"
      end
      project.update_commit commit, :scores   => totals.sum,
                                    :averages => averages.sum/averages.size
    end

    def self.run! options
      new(options).run!
    end

    def meter_file filename
      file_flog = {}
      Centurion::Flog.new(
        file_contents_for(filename), filename
      ).meter do |method_flog|
        file_flog = method_flog.slice :average, :total
        project.update_method commit, filename, method_flog
      end
      project.update_file commit, filename, file_flog
      totals   << file_flog[:total].to_f
      averages << file_flog[:average].to_f
    end

    protected

      def files
        find_tree = "git ls-tree -r #{commit.tree.id} | awk '{print $4}' | egrep \\.rb$"
        file_list = `cd #{project.root} && #{find_tree}`
        files = file_list.split("\n")
        warn "No Ruby source files found in #{project.root}! (at #{sha})" if files.empty?
        files
      end

      def file_contents_for filename
        `cd #{project.root} && git show #{sha}:#{filename}`
      end

      def log string
        puts string
      end
  end
end
