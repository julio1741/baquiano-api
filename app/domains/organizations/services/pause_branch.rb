module Organizations
  # TODO: emit BranchPaused once the domain-events infrastructure exists
  # (Increment 7 — domain_events/outbox_events don't exist yet).
  class PauseBranch
    def self.call(branch:, reason: nil)
      branch.pause!(reason: reason)
      branch
    end
  end
end
