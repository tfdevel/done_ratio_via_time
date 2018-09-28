# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ratio via time plugin”.

# “Done ratio via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

module DoneRatioViaTime
  module Patches
    module IssueRelationsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          helper :issues
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
       .include?(DoneRatioViaTime::Patches::IssueRelationsControllerPatch)
  IssueRelationsController.send(
    :include,
    DoneRatioViaTime::Patches::IssueRelationsControllerPatch
  )
end
