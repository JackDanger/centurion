module Centurion
  class Project

    include Persistence

    attr_reader :root, :name, :repo,
                :run_at, :duration,
                :beginning, :ending, :count

    def initialize root
      @root = root
      @name = ::File.basename root
      @repo = Repo.new root
      @run_at = Time.now.to_i
    end

    def run!
      @beginning = @ending = nil
      @count = 0

      commits do |commit|
        commit.meter
        next if commits_bucket.exists? commit.sha

        @count += 1
        @ending  ||= commit
        @beginning = commit
      end

      @duration = Time.now.to_i - run_at
      update if count > 0
    end

    def key
      name
    end

    def update
      store projects_bucket,
            key,
            :last_sha      => ending.sha,
            :updated_at    => run_at,
            :last_duration => duration
      store runs_bucket,
            run_key,
            :commits       => count,
            :start         => beginning.sha,
            :end           => ending.sha,
            :created_at    => run_at
    end

    def commits(batch_size = 200)
      found = []
      offset = 0
      begin
        batch = Commit.find_all repo, 'HEAD',
                                :max_count => batch_size,
                                :skip => offset
        batch.each {|commit| commit.project = self }

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
  end
end
