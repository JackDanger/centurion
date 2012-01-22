module Grit
  class Commit
    def == other
      sha == other.sha
    end
  end
end
