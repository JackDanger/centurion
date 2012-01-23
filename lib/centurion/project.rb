module Centurion
  class Project

    attr_reader :root, :name, :repo

    def initialize root
      @root = root
      @name = File.basename root
      @repo  = Grit::Repo.new root
    end

    %w{authors commits files methods}.each do |bucket|
      define_method "#{bucket}_bucket" do
        Centurion.db.bucket "#{name}_#{bucket}"
      end
    end

    def update_commit_list
      commits do |commit_set|
        commit_set.each do |commit|
          next if commits_bucket.exists? commit.sha
          doc = commits_bucket.new commit.sha
          parent = commit.parents.first
          doc.data = {
            :processed    => false,
            :sha          => commit.sha,
            :date         => commit.date.to_i,
            :author       => commit.author.to_s,
            :authorDigest => digest(commit.author.to_s),
            :parent       => parent && parent.sha
          }
          doc.store
        end
      end
    end

    def commits(batch_size = 200)
      found = []
      offset = 0
      begin
        batch = repo.commits 'HEAD', batch_size, offset
        if block_given? && !batch.empty?
          yield batch
        else
          found += batch
        end
        offset += batch_size
      end until batch.size < batch_size
      found unless block_given?
    end

    def store_in bucket, key, data
      doc = bucket.get_or_new key
      doc.data = data
      doc.content_type = 'application/json'
      doc.store
    end

    def digest string
      Digest::SHA1.hexdigest(string)[0..6]
    end

  end
end
