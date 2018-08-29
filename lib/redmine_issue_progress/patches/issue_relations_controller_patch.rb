module RedmineIssueProgress
  module Patches
    module IssueRelationsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          before_action :find_optional_issue, only: :destroy
        end
      end

      module InstanceMethods
        private

        def find_optional_issue
          @issue = Issue.find(params[:issue_id]) unless params[:issue_id].blank?
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end

unless IssueRelationsController
       .included_modules
       .include?(RedmineIssueProgress::Patches::IssueRelationsControllerPatch)
  IssueRelationsController.send(
    :include,
    RedmineIssueProgress::Patches::IssueRelationsControllerPatch
  )
end
