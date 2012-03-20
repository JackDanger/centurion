require 'grit'
module Centurion
  class Commit < Grit::Commit

    include Persistence

    attr_reader   :totals,  :averages
    attr_accessor :project, :metered_child

    def initialize *args
      super
      @totals   = Array.new
      @averages = Array.new
    end

    def meter
      files.each &:meter

      puts '' if project.verbose?

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

    def update data
      store commits_bucket, key,
            :sha          => sha,
            :date         => date.to_i,
            :comment      => message,
            :processedAt  => project.run_at,
            :author       => [author.name,
                              author.email],
            :authorDigest => digest(author.to_s),
            :parent       => parent_sha,
            :flog         => data[:flog],
            :flogAverage  => data[:flogAverage]
    end

    def files
      puts "looking for files in #{sha}"
      #find_tree = "git ls-tree -r #{tree.id} | awk '{print $4}' | egrep \\.rb$"
      find_files = if parent_sha
        "git diff #{sha} #{parent_sha} --name-only | egrep \\.rb$"
      else
        "git show #{sha} --name-only --oneline | tail +2 | egrep \\.rb$"
      end
      file_list = `cd #{project.root} && #{find_files}`
      files = file_list.split("\n")
      puts "found #{files.size} files:"
      pp files
      warn "No Ruby source files changed in #{sha})" if files.empty?
      files.map do |filename|
        File.new :commit => self,
                 :name   => filename
      end
    end
  end
end
