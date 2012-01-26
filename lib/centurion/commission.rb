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
      files.each_with_index do |file, idx|
        meter_file file
      end
      project.update_commit commit,
                            :flog        => totals.sum,
                            :flogAverage => averages.sum/averages.size
    end

    def self.run! options
      new(options).run!
    end

    def meter_file filename

      file_flog = {:last_score => last_score(filename)}

      Centurion::Flog.new(
        file_contents_for(filename), filename
      ).meter do |method_flog|

        file_flog.merge! method_flog.slice :average, :total
        method_name = method_flog[:method]
        method_flog[:previous] = last_score filename, method_name
        project.update_method commit,
                              filename,
                              method_name,
                              method_flog
      end

      project.update_file commit,
                          filename,
                          file_flog
      totals   << file_flog[:total].to_f
      averages << file_flog[:average].to_f
    end

    protected

      def last_score filename, method = nil
        method ?
          last_method_score(filename, method) :
          last_file_score(filename)
      end

      def last_method_score filename, method
        return 0 unless sha = last_change(filename)
        key = project.method_key sha, filename, method
        doc = project.methods_bucket.get_or_new key
        doc.data ? doc.data['flog'] : 0
      end

      def last_file_score filename
        return 0 unless sha = last_change(filename)
        key = project.file_key sha, filename
        doc = project.files_bucket.get_or_new key
        doc.data ? doc.data['flog'] : 0
      end

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

      def last_change filename
        return if commit.parents.empty?
        cmd = "git log --name-only #{commit.sha}^ -- '#{filename}' | egrep '^commit [a-g0-9]{40}+$' | cut -d ' ' -f 2 | head -n 1 "
        sha = `cd #{project.root} && #{cmd}`.chomp
        project.commits.detect {|c| c.sha == sha }
      end
  end
end
