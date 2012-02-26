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

    def key sha = commit.sha
      filename = digest file.name
      method   = digest name
      "#{sha}:#{filename}:#{method}"
    end

    def update flog
      store methods_bucket, key,
            :sha          => commit.sha,
            :processedAt  => project.run_at,
						:name         => name,
            :flog         => flog[:total],
            :flogAverage  => flog[:average]
    end
  end
end
