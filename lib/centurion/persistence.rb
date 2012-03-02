module Centurion
  module Persistence

    def store bucket, key, data
      doc = bucket.get_or_new key
      doc.data = data
      doc.content_type = 'application/json'
      doc.store
    end

    def project_name
      is_a?(Project) ? name : project.name
    end

    def projects_bucket
      Centurion.db.bucket 'projects'
    end

    def runs_bucket
      Centurion.db.bucket 'runs'
    end

    def authors_bucket
      Centurion.db.bucket "#{project_name}_authors"
    end

    def commits_bucket
      Centurion.db.bucket "#{project_name}_commits"
    end

    def files_bucket
      Centurion.db.bucket "#{project_name}_files"
    end

    def run_key
      "#{project_name}:#{run_at}"
    end

    def digest string
      Digest::SHA1.hexdigest(string)[0..7]
    end
  end
end
