module Centurion
  class Project

    include Persistence

    attr_accessor :root, :name, :repo,
                  :run_at, :duration, :verbose,
                  :beginning, :ending, :count

    def initialize options
      @root    = options[:project_root]
      @name    = ::File.basename root
      @repo    = Repo.new root
      @run_at  = Time.now.to_i
      @count   = 0
    end

    def run! run_options = {}
      @verbose = run_options[:verbose]
      @beginning = @ending = nil

      commits do |commit|
        next if commits_bucket.exists? commit.key
        puts "processing #{commit.sha}" if verbose

        commit.meter

        self.count += 1
        @ending  ||= commit
        @beginning = commit
      end

      @duration = Time.now - run_at
      update if count > 0
    end

    def verbose?
      verbose
    end

    def key
      name
    end

    def update
      store projects_bucket,
            key,
            :last_sha      => ending.sha,
            :updated_at    => run_at,
            :last_duration => duration.to_f
      store runs_bucket,
            run_key,
            :duration      => duration.to_f,
            :commits       => count,
            :start         => beginning.sha,
            :end           => ending.sha,
            :created_at    => run_at
      store commit_caches_bucket,
            key,
            :shas          => commits.map(&:sha)
    end

    def commit_cache
      commit_caches_bucket.get key
    rescue Riak::FailedRequest
    end

    def commits(batch_size = 200)
      found = []
      offset = 0
      begin
        batch = commit_batch batch_size, offset
        if block_given?
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

    protected

    def commit_batch limit, offset
      Commit.find_all(repo, 'HEAD',
                      :max_count => limit,
                      :skip      => offset
                     ).each { |commit|
                       commit.project = self
                     }
    end
  end
end
