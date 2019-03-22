# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

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

    if DoneRatioSetup.settings[:global][:statuses_for_hours_alignment]
                     .to_a.include?(issue.status_id.to_s) &&
       issue.estimated_hours.to_f == 0 &&
       ![Issue::CALCULATION_TYPE_DESCENDANTS,
         Issue::CALCULATION_TYPE_LINKED].include?(done_ratio_calculation_type)
      return 100
    end

    _, values = time_values(issue)
    done_ratio_result(*values)
  end

  private

  def time_values(issue, ids = [], include_current_time = false)
    return [ids, [0, 0, 0]] if ids.include?(issue.id)

    done_ratio_calculation_type =
      Issue.done_ratio_calculation_type_transformed(issue)

    issue.reload

    time_params =
      case done_ratio_calculation_type
      when Issue::CALCULATION_TYPE_SELF
        done_ratio_self_values(issue)
      when Issue::CALCULATION_TYPE_DESCENDANTS
        done_ratio_descendants_values(issue, ids, include_current_time)
      when Issue::CALCULATION_TYPE_LINKED
        done_ratio_linked_values(issue, ids, include_current_time)
      when Issue::CALCULATION_TYPE_SELF_AND_DESCENDANTS
        done_ratio_self_and_descendants_values(issue, ids)
      when Issue::CALCULATION_TYPE_FULL
        done_ratio_full_values(issue, ids)
      when Issue::CALCULATION_TYPE_MANUAL
        done_ratio_full_values(issue, ids)
      end

    if time_params.present?
      [ids << issue.id, time_params]
    else
      [ids << issue.id, [0, 0, 0]]
    end
  end

  def done_ratio_self_values(issue)
    spent_hours = issue.time_entries.sum(:hours) || 0.0
    primary_assessment_id = DoneRatioSetup.settings[:global][:primary_assessment].to_i
    primary_assessment = CustomValue.find_by(customized_type: 'Issue',
                                             customized_id: issue.id,
                                             custom_field_id: primary_assessment_id)
    custom_value = primary_assessment.value.to_f if primary_assessment
    [spent_hours, issue.estimated_hours.to_f, custom_value]
  end

  def done_ratio_result(spent_hours, estimated_hours, primary_assessment)
    if spent_hours > 0 && estimated_hours.to_f > 0
      if spent_hours >= estimated_hours
        100
      else
        (spent_hours / estimated_hours * 100).to_i
      end
    else
      0
    end
  end

  def ratios_sum(arr)
    arr.reject { |e| e[1].zero? }
       .transpose.map { |e| e.reduce(:+) }
  end

  def done_ratio_descendants_values(issue, ids, include_current_time = false)
    tmp = issue.descendants.map do |child|
      ids, values = time_values(child, ids, true)
      values
    end
    tmp << done_ratio_self_values(issue) if include_current_time
    ratios_sum(tmp)
  end

  def done_ratio_linked_values(issue, ids, include_current_time = false)
    scope =
      Issue.where(id: issue.relations_from
                           .where(relation_type:
                              IssueRelation::TYPE_INCLUDE_TIME_FROM)
                           .select(:issue_to_id))
    tmp = scope.map do |child|
      ids, values = time_values(child, ids, true)
      values
    end
    tmp << done_ratio_self_values(issue) if include_current_time
    ratios_sum(tmp)
  end

  def done_ratio_self_and_descendants_values(issue, ids)
    res = issue.descendants.map do |child|
      ids, values = time_values(child, ids, true)
      values
    end

    ratios_sum(res + [done_ratio_self_values(issue)])
  end

  def done_ratio_full_values(issue, ids)
    scope1 = issue.descendants
    scope2 = Issue.where(id: issue.relations_from
                                  .where(relation_type:
                                    IssueRelation::TYPE_INCLUDE_TIME_FROM)
                                  .select(:issue_to_id))

    scope1_result = scope1.map do |child|
      ids, values = time_values(child, ids, true)
      values
    end

    scope2_result = scope2.map do |child|
      ids, values = time_values(child, ids, true)
      values
    end

    ratios_sum(scope1_result +
      scope2_result +
      [done_ratio_self_values(issue)])
  end
end
