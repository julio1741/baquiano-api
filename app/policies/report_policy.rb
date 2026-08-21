# Backs `authorize :report, :view?` — reports aren't backed by a model, so
# there's no `record` to inspect; Pundit resolves the symbol to this class
# by name (":report" -> "ReportPolicy").
class ReportPolicy < ApplicationPolicy
  def view? = has_permission?("organizations:manage")
end
