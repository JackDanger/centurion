module Centurion
  class Project
    module Persistence

      def store_in bucket, key, data
        doc = bucket.get_or_new key
        doc.data = data
        doc.content_type = 'application/json'
        doc.store
      end

      def projects_bucket
        Centurion.db.bucket 'projects'
      end

      def runs_bucket
        Centurion.db.bucket 'runs'
      end

      def project_key
        name
      end

      def authors_bucket
        Centurion.db.bucket "#{name}_authors"
      end

      def commits_bucket
        Centurion.db.bucket "#{name}_commits"
      end

      def files_bucket
        Centurion.db.bucket "#{name}_files"
      end

      def methods_bucket
        Centurion.db.bucket "#{name}_methods"
      end

      def run_key
        "#{name}:#{run_at}"
      end

      def commit_key commit
        commit.sha
      end

      def file_key commit, file
        sha = commit.sha
        file = digest file
        "#{sha}:#{file}"
      end

      def method_key commit, file, method
        sha    = commit.sha
        file   = digest file
        method = digest method
        "#{sha}:#{file}:#{method}"
      end

      def digest string
        Digest::SHA1.hexdigest(string)[0..7]
      end
    end
  end
end
