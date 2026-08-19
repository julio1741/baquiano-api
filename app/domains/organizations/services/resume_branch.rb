module Organizations
  class ResumeBranch
    def self.call(branch:)
      branch.resume!
      branch
    end
  end
end
