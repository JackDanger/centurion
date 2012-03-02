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
    end

    def run! run_options = {}
      @verbose   = run_options[:verbose]
      @beginning = @ending = nil
      @count     = 0

      commits.each do |commit|
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
    end

    def commits(batch_size = 200)
      Commit.find_all(repo,
                      'HEAD',
                      :max_count => 1_000_000
                     ).each { |commit|
                       commit.project = self
                     }.reverse
    end
  end
end
