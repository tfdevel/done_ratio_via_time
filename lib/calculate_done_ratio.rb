class CalculateDoneRatio
  def self.call(*args)
    new.call(*args)
  end

  def call(original_issue)
    issue = original_issue.clone
    done_ratio_calculation_type =
      Issue.done_ratio_calculation_type_transformed(issue)

    if done_ratio_calculation_type == Issue::CALCULATION_TYPE_MANUAL
      return issue.done_ratio
    end

    done_ratio_result(*time_values(issue))
  end

  private

  def time_values(issue, include_current_time = false)
    done_ratio_calculation_type =
      Issue.done_ratio_calculation_type_transformed(issue)

    issue.reload

    time_params =
      case done_ratio_calculation_type
      when Issue::CALCULATION_TYPE_SELF
        done_ratio_self_values(issue)
      when Issue::CALCULATION_TYPE_DESCENDANTS
        done_ratio_descendants_values(issue, include_current_time)
      when Issue::CALCULATION_TYPE_LINKED
        done_ratio_linked_values(issue, include_current_time)
      when Issue::CALCULATION_TYPE_SELF_AND_DESCENDANTS
        done_ratio_self_and_descendants_values(issue)
      when Issue::CALCULATION_TYPE_FULL
        done_ratio_full_values(issue)
      when Issue::CALCULATION_TYPE_MANUAL
        done_ratio_self_values(issue)
      end

    time_params.present? ? time_params : [0, 0]
  end

  def done_ratio_self_values(issue)
    spent_hours = issue.time_entries.sum(:hours) || 0.0
    [spent_hours, issue.estimated_hours.to_f]
  end

  def done_ratio_result(spent_hours, estimated_hours)
    if spent_hours > 0 && estimated_hours.to_f > 0
      if spent_hours >= estimated_hours
        100
      else
        (spent_hours / estimated_hours * 100).round
      end
    else
      0
    end
  end

  def done_ratio_descendants_values(issue, include_current_time = false)
    tmp = issue.descendants.map { |child| time_values(child, true) }
    tmp << done_ratio_self_values(issue) if include_current_time
    tmp.transpose.map { |e| e.reduce(:+) }
  end

  def done_ratio_linked_values(issue, include_current_time = false)
    scope =
      Issue.where(id: issue.relations_from
                           .where(relation_type:
                              IssueRelation::TYPE_INCLUDE_TIME_FROM)
                           .select(:issue_to_id))
    tmp = scope.map { |child| time_values(child, true) }
    tmp << done_ratio_self_values(issue) if include_current_time
    tmp.transpose.map { |e| e.reduce(:+) }
  end

  def done_ratio_self_and_descendants_values(issue)
    res = issue.descendants.map { |child| time_values(child, true) }
    (res + [done_ratio_self_values(issue)]).transpose.map { |e| e.reduce(:+) }
  end

  def done_ratio_full_values(issue)
    scope1 = issue.descendants
    scope2 = Issue.where(id: issue.relations_from
                                  .where(relation_type:
                                    IssueRelation::TYPE_INCLUDE_TIME_FROM)
                                  .select(:issue_to_id))
    (scope1.map { |child| time_values(child, true) } +
      scope2.map { |child| time_values(child, true) } +
      [done_ratio_self_values(issue)]).transpose.map { |e| e.reduce(:+) }
  end
end
