require 'grit'
module Centurion
  class Commit < Grit::Commit

    include Persistence

    attr_reader   :totals,  :averages
    attr_accessor :project

    def initialize *args
      super
      @totals   = Array.new
      @averages = Array.new
    end

    def meter
      files.each &:meter

      total   =   totals.reduce(&:+).to_f
      average = averages.reduce(&:+).to_f / averages.size.to_f

      update :flog        => total,
             :flogAverage => average
    end

    def key
      sha
    end

    def parent_sha
      if parent = parents.first
        parent.sha
      end
    end

    def update flog
      store commits_bucket, key,
            :sha          => sha,
            :date         => date.to_i,
            :comment      => message,
            :processedAt  => project.run_at,
            :author       => [author.name,
                              author.email],
            :authorDigest => digest(author.to_s),
            :parent       => parent_sha,
            :flog         => flog[:total],
            :flogAverage  => flog[:average]
    end

    def files
      find_tree = "git ls-tree -r #{tree.id} | awk '{print $4}' | egrep \\.rb$"
      file_list = `cd #{project.root} && #{find_tree}`
      files = file_list.split("\n")
      warn "No Ruby source files found in #{project.root}! (at #{sha})" if files.empty?
      files.map do |filename|
        File.new :commit => self,
                 :name   => filename
      end
    end
  end
end
