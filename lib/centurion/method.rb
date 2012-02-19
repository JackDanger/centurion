module Centurion
  class Method

    include Persistence

    attr_reader :name,
                :file,
                :commit,
                :project

    def initialize options
      @name    = options[:name]
      @file    = options[:file]
      @commit  = file.commit
      @project = commit.project
    end

    def key
      sha      = commit.sha
      filename = digest file.name
      method   = digest name
      "#{sha}:#{filename}:#{method}"
    end

    def update flog
      store methods_bucket, key,
            :sha          => commit.sha,
            :processedAt  => project.run_at,
            :flog         => flog[:total],
            :flogAverage  => flog[:average],
            :flogDelta    => flog[:total].to_f - flog[:lastFlog].to_f
    end


    def last_score
      return 0 unless sha = commit.last_change
      doc = methods_bucket.get_or_new key
      doc.data ? doc.data['flog'] : 0
    end
  end
end