module Centurion
  class Project

    include Persistence

    attr_reader :root, :name, :repo

    def initialize root
      @root = root
      @name = File.basename root
      @repo  = Grit::Repo.new root
      @collector = Collector.new :project => self
    end

    def run!
      count = 0
      start = Time.now
      commits do |commit|
        next if commits_bucket.exists? commit.sha
        collector.meter commit
        last_commit = commit
        count += 1
      end
      update_project count, start, last_commit
    end

    def update_project count, start, last_commit
      store_in projects_bucket,
               project.name,
               :last_sha      => last_commit.sha,
               :updated_at    => Time.now.to_i,
               :last_duration => Time.now - start
    end

    def update_commit commit, data
      key = commit_key commit
      doc = commits_bucket.new key
      doc.data = data
      doc.store
    end

    def update_file commit, filename, flog
      previous_score = previous_score_for commit, filename
      key = file_key commit, filename
      doc = files_bucket.new key
      doc.data = {
        :sha          => commit.sha,
        :date         => commit.date.to_i,
        :comment      => commit.message,
        :processedAt  => Time.now.to_i,
        :author       => [commit.author.name,
                          commit.author.email],
        :authorDigest => digest(commit.author.to_s),
        :parent       => parent_sha(commit),
        :score        => flog[:total],
        :scoreDelta   => flog[:total] - previous_score
        :scoreAverage => flog[:average],
      }
      doc.store
    end

    def update_method commit, filename, flog
      method_name = flog[:method]
      previous_score = 0#previous_score_for commit, file, method
      key = method_key commit, filename, method_name
      doc = files_bucket.new key
      doc.data = {
        :sha          => commit.sha,
        :date         => commit.date.to_i,
        :comment      => commit.message,
        :processedAt  => Time.now.to_i,
        :author       => [commit.author.name,
                          commit.author.email],
        :authorDigest => digest(commit.author.to_s),
        :parent       => parent_sha(commit),
        :score        => flog[:total],
        :average      => flog[:average],
        :scoreDelta   => flog[:total] - previous_score
      }
      doc.store
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

    def previous_score_for commit, filename
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
