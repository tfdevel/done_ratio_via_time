# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

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
    parent = issue.parent

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
    issue.update_column(:done_ratio, CalculateDoneRatio.call(issue))
    current_issue_journal.save
  end
end
