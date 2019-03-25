# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

class UpdateParentsDoneRatio
  def self.call(*args)
    new.call(*args)
  end

  def call(issue)
    update_parents(issue)
  end

  private

  def update_parents(issue)
    issues_from_relations = Issue.where(id: issue.relations_to
                                 .where(relation_type:
                                   IssueRelation::TYPE_INCLUDE_TIME_FROM)
                                 .select(:issue_from_id)).to_a
    parent =
      if issue.parent_id
        issue.parent
      elsif issue.parent_id_was
        Issue.find_by_id(issue.parent_id_was)
      end

    issues_from_relations.each do |e|
      update_linked(e)
      update_parents(e)
    end

    return unless parent

    update_parent(parent)
    update_parents(parent)
  end

  def update_linked(issue)
    current_mode = Issue.done_ratio_calculation_type_transformed(issue)
    if [Issue::CALCULATION_TYPE_FULL,
        Issue::CALCULATION_TYPE_LINKED].include?(current_mode)
      update_issue(issue)
    end
  end

  def update_parent(issue)
    current_mode = Issue.done_ratio_calculation_type_transformed(issue)
    unless [Issue::CALCULATION_TYPE_MANUAL,
            Issue::CALCULATION_TYPE_SELF].include?(current_mode)
      update_issue(issue)
    end
  end

  def update_issue(issue)
    current_issue_journal =
      issue.current_journal || issue.init_journal(User.current)
    issue.update_columns(done_ratio: CalculateDoneRatio.call(issue),
                         total_spent_hours: issue.time_values[0],
                         total_estimated_hours: issue.time_values[1])
    current_issue_journal.save
  end
end
