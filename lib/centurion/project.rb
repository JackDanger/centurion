module Centurion
  class Project

    include Persistence

    attr_reader :root, :name, :repo,
                :run_at, :duration,
                :beginning, :ending, :count

    def initialize root
      @root = root
      @name = File.basename root
      @repo  = Grit::Repo.new root
    end

    def run!
      @run_at = Time.now.to_i
      @beginning = @ending = nil
      @count = 0

      commits do |commit|
        next if commits_bucket.exists? commit.sha

        Commission.run! :project => self, :commit => commit
        @count += 1
        @ending  ||= commit
        @beginning = commit
      end

      @duration = Time.now.to_i - run_at
      update_project if count > 0
    end

    def update_project
      store_in projects_bucket,
               name,
               :last_sha      => ending.sha,
               :updated_at    => run_at,
               :last_duration => duration
      store_in runs_bucket,
               run_key,
               :commits       => count,
               :start         => beginning.sha,
               :end           => ending.sha,
               :created_at    => run_at
    end

    def update_commit commit, flog
      previous_score = previous_score_for commit
      store_in commits_bucket,
               commit_key(commit),
               :sha          => commit.sha,
               :date         => commit.date.to_i,
               :comment      => commit.message,
               :processedAt  => run_at,
               :author       => [commit.author.name,
                                 commit.author.email],
               :authorDigest => digest(commit.author.to_s),
               :parent       => parent_sha(commit),
               :flog         => flog[:total],
               :flogAverage  => flog[:average],
               :flogDelta    => flog[:total].to_f - previous_score
    end

    def update_file commit, filename, flog
      previous_score = previous_score_for commit, filename
      store_in files_bucket,
               file_key(commit, filename),
               :sha          => commit.sha,
               :processedAt  => run_at,
               :flog         => flog[:total],
               :flogAverage  => flog[:average],
               :flogDelta    => flog[:total].to_f - previous_score
    end

    def update_method commit, filename, flog
      method_name = flog[:method]
      previous_score = 0#previous_score_for commit, file, method
      store_in methods_bucket,
               method_key(commit, filename, method_name),
               :sha          => commit.sha,
               :processedAt  => run_at,
               :flog         => flog[:total],
               :flogAverage  => flog[:average],
               :flogDelta    => flog[:total].to_f - previous_score
    end

    def commits(batch_size = 200)
      found = []
      offset = 0
      begin
        batch = repo.commits 'HEAD', batch_size, offset
        if block_given? && !batch.empty?
          batch.each do |commit|
            yield commit
          end
        else
          found += batch
        end
        offset += batch_size
      end until batch.size < batch_size
      found unless block_given?
    end

    def previous_score_for commit, filename = nil
      # TODO
      0
    end

    def parent_sha commit
      if parent = commit.parents.first
        parent.sha
      end
    end
  end
end
