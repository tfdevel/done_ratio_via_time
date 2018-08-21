module RedmineIssueProgress
  module Patches
    # Show calculation mode name in issue history
    module IssuesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :show_detail, :done_ratio_calculation_type
        end
      end

      module InstanceMethods
        def show_detail_with_done_ratio_calculation_type(detail,
                                                         no_html = false,
                                                         options = {})
          if detail.prop_key == 'done_ratio_calculation_type'
            if detail.old_value
              detail.old_value =
                "'#{Issue.done_ratio_calculation_type_name(detail.old_value.to_i)}'"
            end
            if detail.value
              detail.value =
                "'#{Issue.done_ratio_calculation_type_name(detail.value.to_i)}'"
            end
          end
          show_detail_without_done_ratio_calculation_type(detail, no_html, options)
        end
      end
    end
  end
end

unless IssuesHelper.included_modules
                   .include?(RedmineIssueProgress::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineIssueProgress::Patches::IssuesHelperPatch)
end
