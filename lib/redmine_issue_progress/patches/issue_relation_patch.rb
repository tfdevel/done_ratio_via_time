module RedmineIssueProgress
  module Patches
    # Add new issue relation type
    module IssueRelationPatch
      def self.included(base)
        include_time_from = 'include_time_from'

        new_types = base::TYPES.merge(
          include_time_from => {
            name: :label_include_time_from,
            sym_name: :label_include_time_by,
            order: 10,
            sym: include_time_from
          }
        )

        base.class_eval do
          const_set :TYPE_INCLUDE_TIME_FROM, include_time_from

          remove_const :TYPES
          const_set :TYPES, new_types.freeze

          inclusion_validator =
            _validators[:relation_type].find { |v| v.kind == :inclusion }
          inclusion_validator.instance_variable_set(:@delimiter, new_types.keys)
        end
      end
    end
  end
end

unless Issue.included_modules
            .include?(RedmineIssueProgress::Patches::IssueRelationPatch)
  IssueRelation.send(:include,
                     RedmineIssueProgress::Patches::IssueRelationPatch)
end
