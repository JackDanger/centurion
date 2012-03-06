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
      if flog = calculated_unchanged_score
        if project.verbose?
          print '>'
          STDOUT.flush
        end
      else
        Flog.new(contents, name).meter do |method_flog|
          flog = method_flog.slice :average, :total
          break
        end
        if project.verbose?
          print '.'
          STDOUT.flush
        end
      end
      flog ||= {}

      commit.totals   << flog[:total].to_f
      commit.averages << flog[:average].to_f

      update flog
    end

    def calculated_unchanged_score
      if unchanged = calculated_unchanged_child || calculated_unchanged_parent
        data = unchanged.slice 'flog', 'flogAverage'
        return if data.values.blank?
        {
          :total   => data['flog'],
          :average => data['flogAverage']
        }
      end
    end

    def key sha = commit.sha
      "#{sha}:#{digest name}"
    end

    def update flog
      store files_bucket, key,
            :sha          => commit.sha,
            :name         => name,
            :processedAt  => project.run_at,
            :flog         => flog[:total],
            :flogAverage  => flog[:average]
    end

    def contents
      `cd #{project.root} && git show #{commit.sha}:#{name}`
    end

    def last_changed
      @last_changed ||= File.last_changed self, commit
    end

    def self.last_changed file, commit
      return if commit.parents.empty?
      cmd = "git log --name-only #{commit.sha}^ -- '#{file.name}' | egrep '^commit [a-g0-9]{40}+$' | cut -d ' ' -f 2 | head -n 1 "
      sha = `cd #{commit.project.root} && #{cmd}`.chomp
      found = Commit.find_all(commit.project.repo, sha, :max_count => 1).first
      found && found.sha
    end

    protected

      def calculated_unchanged_parent
        changed_sha = last_changed
        if commit.parent_sha && changed_sha && commit.parent_sha != changed_sha
          files_bucket.get(key(commit.parent_sha)).data
        end
      rescue Riak::HTTPFailedRequest
      end

      def calculated_unchanged_child
        if commit.metered_child &&
           (changed_sha = File.last_changed self, commit.metered_child) &&
           commit.sha != changed_sha
          files_bucket.get(key(commit.metered_child.sha)).data
        end
      rescue Riak::HTTPFailedRequest
      end
  end
end
