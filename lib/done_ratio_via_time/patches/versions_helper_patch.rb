# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

module DoneRatioViaTime
  module Patches
    module VersionsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.class_eval do
          alias_method_chain :render_issue_status_by, :new_logic
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        STATUS_BY_CRITERIAS = %w(tracker status priority author assigned_to category)

        def render_issue_status_by_with_new_logic(version, criteria)
          criteria = 'tracker' unless STATUS_BY_CRITERIAS.include?(criteria)

          h = Hash.new {|k,v| k[v] = [0, 0]}
          begin
            issues = version.fixed_issues.where("estimated_hours > ?", "0")
            issues.group(criteria).sum(:estimated_hours).each do |c,s|
              h[c][0] = s
            end
            issues.joins(:time_entries).group(criteria).sum(:hours).each do |c,s|
              h[c][1] = s
            end
          rescue ActiveRecord::RecordNotFound
          end
          counts = h.keys.sort {|a,b| a.nil? ? 1 : (b.nil? ? -1 : a <=> b)}.collect {|k| {:group => k, :total => h[k][0], :open => h[k][1], :closed => (h[k][0] - h[k][1])}}
          max = counts.collect {|c| c[:total]}.max

          render :partial => 'issue_counts', :locals => {:version => version, :criteria => criteria, :counts => counts, :max => max}
        end
      end
    end
  end
end

unless VersionsHelper.included_modules
            .include?(DoneRatioViaTime::Patches::VersionsHelperPatch)
  VersionsHelper.send(:include, DoneRatioViaTime::Patches::VersionsHelperPatch)
end
