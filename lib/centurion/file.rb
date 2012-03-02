module Centurion
  class File

    include Persistence

    attr_reader :name,
                :commit,
                :project

    def initialize options
      @name    = options[:name]
      @commit  = options[:commit]
      @project = commit.project
    end

    def meter
      flog = {}
      Flog.new(contents, name).meter do |method_flog|
        flog = method_flog.slice :average, :total
        break
      end

      commit.totals   << flog[:total].to_f
      commit.averages << flog[:average].to_f

      update flog
    end


    def key sha = commit.sha
      "#{sha}:#{digest name}"
    end

    def update flog
      store files_bucket, key,
            :sha          => commit.sha,
            :processedAt  => project.run_at,
            :flog         => flog[:total],
            :flogAverage  => flog[:average]
    end

    def contents
      `cd #{project.root} && git show #{commit.sha}:#{name}`
    end

    def last_change
      return if commit.parents.empty?
      cmd = "git log --name-only #{commit.sha}^ -- '#{name}' | egrep '^commit [a-g0-9]{40}+$' | cut -d ' ' -f 2 | head -n 1 "
      sha = `cd #{project.root} && #{cmd}`.chomp
      project.commits.detect {|c| c.sha == sha }
    end
  end
end
