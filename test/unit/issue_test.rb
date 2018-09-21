# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

require File.expand_path('../../test_helper', __FILE__)

class IssueTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false
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
    @issue.project.enable_module!(:issue_progress)
    @issue.update_columns(estimated_hours: 4, done_ratio_calculation_type: Issue::CALCULATION_TYPE_MANUAL)
    @issue.time_entries.create!(hours: 2, user: User.first, spent_on: Date.current)
    User.current = User.first
    manager_role = Role.find_by_name("Manager")
    manager_role.permissions << :edit_done_ratio_calculation_type
    manager_role.save!

    Member.create!(project: @issue.project, principal: User.first, roles: [manager_role])
    @issue.project.reload
  end

  test 'change done_ratio with manual mode' do
    @issue.safe_attributes = { 'done_ratio' => '56' }
    @issue.save
    assert_equal(56, @issue.done_ratio)
  end

  test 'change done_ratio with any not manual mode' do
    Issue::DONE_RATIO_CALCULATION_TYPES.except(Issue::CALCULATION_TYPE_DEFAULT,
                                               Issue::CALCULATION_TYPE_MANUAL).keys.each do |mode|

      done_ratio = (1..100).to_a.sample
      @issue.safe_attributes = { 'done_ratio_calculation_type' => mode.to_s,
                                 'done_ratio' => done_ratio.to_s }
      @issue.save
      assert_equal(mode, @issue.done_ratio_calculation_type)
      assert_not_equal(done_ratio, @issue.done_ratio)
    end
  end

  test 'update done_ratio on estimated_hours/spent_hours/mode change' do
    issue2 = Issue.generate!
    issue2.parent_issue_id = @issue.id
    issue2.estimated_hours = 2
    issue2.save!
    @issue.update_columns(done_ratio_calculation_type: Issue::CALCULATION_TYPE_FULL)
    assert_equal(0, @issue.done_ratio)
    @issue.safe_attributes = { 'estimated_hours' => '5' }
    @issue.save
    assert_equal(5, @issue.estimated_hours)
    assert_equal(28, @issue.done_ratio) # 2/7 = 0.28
    @issue.time_entries.create!(user: User.first, hours: 1, spent_on: Date.current)
    assert_equal(42, @issue.reload.done_ratio) # 3/7 = 0.42
    issue2.time_entries.create!(user: User.first, hours: 0.5, spent_on: Date.current)
    @issue.safe_attributes = { 'done_ratio_calculation_type' => Issue::CALCULATION_TYPE_DESCENDANTS.to_s }
    @issue.save
    assert_equal(25, @issue.reload.done_ratio) # 0.5/2 = 0.25
  end

  test '#update parents done_ratio on child param change' do
    @issue.update_column(:done_ratio_calculation_type, Issue::CALCULATION_TYPE_LINKED)
    issue1 = Issue.generate!
    issue1.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DESCENDANTS
    issue1.estimated_hours = 3
    issue1.time_entries.new(user: User.first, hours: 2, spent_on: Date.current)
    issue1.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue1,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(0, issue1.done_ratio)
    assert_equal(66, @issue.reload.done_ratio) # 2/3 ~ 0.66

    issue2 = Issue.generate!
    issue2.done_ratio_calculation_type = Issue::CALCULATION_TYPE_FULL
    issue2.estimated_hours = 5
    issue2.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue2.save!
    IssueRelation.create!(issue_from: @issue, issue_to: issue2,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(80, issue2.done_ratio) # 4/5 = 0.8
    assert_equal(75, @issue.reload.done_ratio) # 6/8 = 0.75

    issue3 = Issue.generate!
    issue3.parent_issue_id = issue2.id
    issue3.done_ratio_calculation_type = Issue::CALCULATION_TYPE_DEFAULT
    issue3.estimated_hours = 5
    issue3.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue3.save!

    assert_equal(0, issue3.done_ratio)
    assert_equal(69, @issue.reload.done_ratio) # 9/13 = 0.69

    issue4 = Issue.generate!
    issue4.parent_issue_id = issue1.id
    issue4.done_ratio_calculation_type = Issue::CALCULATION_TYPE_SELF
    issue4.estimated_hours = 9
    issue4.time_entries.new(user: User.first, hours: 4, spent_on: Date.current)
    issue4.save!

    assert_equal(44, issue4.done_ratio) # 4/9 = 0.44
    assert_equal(59, @issue.reload.done_ratio) # 13/22 = 0.59

    issue5 = Issue.generate!
    issue5.done_ratio_calculation_type = Issue::CALCULATION_TYPE_MANUAL
    issue5.estimated_hours = 7
    issue5.time_entries.new(user: User.first, hours: 3, spent_on: Date.current)
    issue5.save!
    relation =
      IssueRelation.create!(issue_from: issue2, issue_to: issue5,
                            relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)

    assert_equal(0, issue5.done_ratio)
    assert_equal(55, @issue.reload.done_ratio) # 16/29 ~ 0.55
    issue5.safe_attributes = { 'estimated_hours' => '8' }
    issue5.save
    assert_equal(53, @issue.reload.done_ratio) # 16/30 ~ 0.53
    issue1.safe_attributes = { 'done_ratio_calculation_type' => Issue::CALCULATION_TYPE_MANUAL.to_s }
    issue1.save
    assert_equal(53, @issue.reload.done_ratio) # 16/30 ~ 0.53
    issue4.safe_attributes = { 'parent_issue_id' => issue2.id.to_s }
    issue4.save
    assert_equal(53, @issue.reload.done_ratio) # 16/30 ~ 0.53
    issue3.time_entries.create(user: User.first, hours: 1, spent_on: Date.current)
    assert_equal(56, @issue.reload.done_ratio) # 17/30 ~ 0.56
    relation.destroy
    assert_equal(63, @issue.reload.done_ratio) # 14/22 ~ 0.63
    IssueRelation.create!(issue_from: @issue, issue_to: issue5,
                          relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM)
    assert_equal(56, @issue.reload.done_ratio) # 17/30 ~ 0.56
  end
end
