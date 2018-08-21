require File.expand_path('../../test_helper', __FILE__)

class CalculateDoneRatioTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  def setup
    @issue = Issue.generate!
    @issue.update_columns(estimated_hours: 4,
                          done_ratio_calculation_type: Issue::CALCULATION_TYPE_MANUAL)
    @issue.time_entries.create!(hours: 2, user: User.first, spent_on: Date.current)
    User.current = User.first
  end

  test '#done_ratio_self' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_SELF)

    assert_equal(50, CalculateDoneRatio.call(@issue)) # 2/4 = 0.5
    @issue.update_column(:estimated_hours, nil)
    assert_equal(0, CalculateDoneRatio.call(@issue))
    @issue.update_column(:estimated_hours, 4)
    @issue.time_entries.destroy_all
    assert_equal(0, CalculateDoneRatio.call(@issue))
  end

  test '#done_ratio_descendants' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_DESCENDANTS)
    issue2 = Issue.generate!
    issue2.parent_issue_id = @issue.id
    issue2.estimated_hours = 2
    issue2.save!
    assert_equal(0, CalculateDoneRatio.call(@issue))
    issue2.time_entries.create!(user: User.first, hours: 0.5, spent_on: Date.current)
    assert_equal(25, CalculateDoneRatio.call(@issue)) # 0.5/2 = 0.25
  end

  test '#done_ratio_self_and_descendants' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_SELF_AND_DESCENDANTS)
    issue2 = Issue.generate!
    issue2.parent_issue_id = @issue.id
    issue2.estimated_hours = 2
    issue2.save!
    assert_equal(33, CalculateDoneRatio.call(@issue))  # 2/6 ~ 0.33
    issue2.time_entries.create!(user: User.first, hours: 0.5, spent_on: Date.current)
    assert_equal(42, CalculateDoneRatio.call(@issue)) # 2.5/6 ~ 0.42
  end

  test '#done_ratio_linked' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_LINKED)
    issue2 = Issue.generate!
    issue2.estimated_hours = 2
    issue2.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue2,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(0, CalculateDoneRatio.call(@issue))
    issue2.time_entries.create!(user: User.first, hours: 0.5, spent_on: Date.current)
    assert_equal(25, CalculateDoneRatio.call(@issue)) # 0.5/2 = 0.25
  end

  test '#done_ratio_full' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_FULL)
    issue2 = Issue.generate!
    issue2.estimated_hours = 2
    issue2.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue2,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)
    issue3 = Issue.generate!
    issue3.parent_issue_id = @issue.id
    issue3.estimated_hours = 3.5
    issue3.save!

    assert_equal(21, CalculateDoneRatio.call(@issue)) # 2/9.5 ~ 0.21
    issue2.time_entries.create!(user: User.first, hours: 0.5, spent_on: Date.current)
    assert_equal(26, CalculateDoneRatio.call(@issue)) # 2.5/9.5 ~ 0.26
    issue3.time_entries.create!(user: User.first, hours: 1, spent_on: Date.current)
    assert_equal(37, CalculateDoneRatio.call(@issue)) # 3.5/9.5 ~ 0.37
  end

  test '#done_ratio_full chain from 3 issues' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_FULL)
    issue2 = Issue.generate!
    issue2.parent_issue_id = @issue.id
    issue2.done_ratio_calculation_type = Issue::CALCULATION_TYPE_LINKED
    issue2.estimated_hours = 3.5
    issue2.save!

    issue3 = Issue.generate!
    issue3.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF
    issue3.estimated_hours = 2
    issue3.save!
    IssueRelation.create!(issue_from: issue2, issue_to: issue3,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(21, CalculateDoneRatio.call(@issue)) # 2/9.5 ~ 0.21
    issue2.time_entries.create!(user: User.first, hours: 0.5, spent_on: Date.current)
    assert_equal(26, CalculateDoneRatio.call(@issue)) # 2.5/9.5 ~ 0.26
    issue3.time_entries.create!(user: User.first, hours: 1, spent_on: Date.current)
    assert_equal(37, CalculateDoneRatio.call(@issue)) # 3.5/9.5 ~ 0.37
  end

  test '#done_ratio_full tree from 6 issues' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_LINKED)
    issue1 = Issue.generate!
    issue1.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DESCENDANTS
    issue1.estimated_hours = 3
    issue1.time_entries.new(user: User.first, hours: 2, spent_on: Date.current)
    issue1.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue1,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    issue2 = Issue.generate!
    issue2.done_ratio_calculation_type = Issue::CALCULATION_TYPE_FULL
    issue2.estimated_hours = 5
    issue2.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue2.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue2,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    issue3 = Issue.generate!
    issue3.parent_issue_id = issue2.id
    issue3.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DEFAULT
    issue3.estimated_hours = 5
    issue3.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue3.save!

    issue4 = Issue.generate!
    issue4.parent_issue_id = issue1.id
    issue4.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF
    issue4.estimated_hours = 9
    issue4.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue4.save!

    issue5 = Issue.generate!
    issue5.done_ratio_calculation_type = Issue::CALCULATION_TYPE_MANUAL
    issue5.estimated_hours = 7
    issue5.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue5.save!
    IssueRelation.create!(issue_from: issue2, issue_to: issue5,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(59, CalculateDoneRatio.call(issue2)) # 10/17 ~ 0.59
    assert_equal(55, CalculateDoneRatio.call(@issue)) # 16/29 ~ 0.55
  end

  test '#done_ratio_full tree from 6 issues with self mode in the centre' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_LINKED)
    issue1 = Issue.generate!
    issue1.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DESCENDANTS
    issue1.estimated_hours = 3
    issue1.time_entries.new(user: User.first, hours: 2, spent_on: Date.current)
    issue1.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue1,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    issue2 = Issue.generate!
    issue2.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF
    issue2.estimated_hours = 5
    issue2.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue2.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue2,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    issue3 = Issue.generate!
    issue3.parent_issue_id = issue2.id
    issue3.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DEFAULT
    issue3.estimated_hours = 5
    issue3.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue3.save!

    issue4 = Issue.generate!
    issue4.parent_issue_id = issue1.id
    issue4.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF
    issue4.estimated_hours = 9
    issue4.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue4.save!

    issue5 = Issue.generate!
    issue5.done_ratio_calculation_type = Issue::CALCULATION_TYPE_MANUAL
    issue5.estimated_hours = 7
    issue5.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue5.save!
    IssueRelation.create!(issue_from: issue2, issue_to: issue5,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(80, CalculateDoneRatio.call(issue2)) # 4/5 = 0.8
    assert_equal(59, CalculateDoneRatio.call(@issue)) # 10/17 ~ 0.59
  end

  test '#done_ratio_full tree from 6 issues with full mode in the root' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_FULL)
    issue1 = Issue.generate!
    issue1.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DESCENDANTS
    issue1.estimated_hours = 3
    issue1.time_entries.new(user: User.first, hours: 2, spent_on: Date.current)
    issue1.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue1,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    issue2 = Issue.generate!
    issue2.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF_AND_DESCENDANTS
    issue2.estimated_hours = 5
    issue2.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue2.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue2,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    issue3 = Issue.generate!
    issue3.parent_issue_id = issue2.id
    issue3.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DEFAULT
    issue3.estimated_hours = 5
    issue3.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue3.save!

    issue4 = Issue.generate!
    issue4.parent_issue_id = issue1.id
    issue4.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF
    issue4.estimated_hours = 9
    issue4.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue4.save!

    issue5 = Issue.generate!
    issue5.done_ratio_calculation_type = Issue::CALCULATION_TYPE_MANUAL
    issue5.estimated_hours = 7
    issue5.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue5.save!
    IssueRelation.create!(issue_from: issue2, issue_to: issue5,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(70, CalculateDoneRatio.call(issue2)) # 7/10 = 0.7
    assert_equal(58, CalculateDoneRatio.call(@issue)) # 15/26 ~ 0.58
  end
end
