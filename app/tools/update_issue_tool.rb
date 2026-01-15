class UpdateIssueTool < RedmineTool
  description "Update an issue"
  input_schema(
    properties: {
      issue_id: {
        type: "integer",
        description: "The unique numeric ID of the issue to be updated. The authenticated user must have permission to view and edit this specific issue."
      },
      project_id: {
        type: "integer",
        description: "Numeric Redmine project ID which the issue belongs to. This must be a project where the authenticated user has permission to access the project."
      },
      tracker_id: {
        type: "integer",
        description: "Tracker ID to use for the issue (e.g. Bug, Feature, Support). The tracker must be enabled for the specified project."
      },
      status_id: {
        type: "integer",
        description: "Optional issue status ID. If omitted, default issue status will be used."
      },
      priority_id: {
        type: "integer",
        description: "Optional issue priority ID. If omitted, Redmine's default or middle priority will be used."
      },
      subject: {
        type: "string",
        description: "Short summary of the issue. This is a required field and must not be empty."
      },
      description: {
        type: "string",
        description: "Detailed description of the issue. Supports the same formatting as Redmine issue descriptions. Optional."
      },
      category_id: {
        type: "integer",
        description: "Optional issue category ID. Categories are project-specific classifications (e.g. 'Backend', 'UI', 'Documentation'). The category must belong to the specified project. If omitted, no category will be assigned to the issue."
      },
      fixed_version_id: {
        type: "integer",
        description: "Optional ID of the target version for the issue (also known as 'Fixed Version'). 'Fixed Version' is the historical name and is still used internally and in the Redmine REST API. The version must belong to the specified project and be open or otherwise available for issue assignment."
      },
      assigned_to_id: {
        type: "integer",
        description: "Optional user ID to assign the issue to. The user must be a member of the project (or otherwise eligible for assignment based on project settings). Currently, assignment is only supported by numeric user ID; assigning by login or name is not supported."
      },
      parent_issue_id: {
        type: "integer",
        description: "Optional ID of the parent issue. The parent issue must belong to the same project, and the authenticated user must have permission to manage subtasks in the project."
      },
      custom_fields: {
        type: "array",
        description: "Optional list of Redmine custom field values to set on the issue. Each entry specifies the custom field ID and the value to assign. Only custom fields that are enabled for issues, visible to the user, and applicable to the selected project and tracker will be accepted.",
        items: {
          type: "object",
          properties: {
            id: {
              type: "integer",
              description: "ID of the Redmine custom field."
            },
            value: {
              type: "string",
              description: "Value to assign to the custom field."
            }
          },
          required: %w[id value]
        }
      },
      watcher_user_ids: {
        type: "array",
        description: "Optional array of user IDs to add as watchers of the issue. Watchers will receive notifications about updates to the issue. The authenticated user must have permission to add watchers, and each user ID must refer to a valid user who is allowed to watch issues in the project.",
        items: {
          type: "integer"
        }
      },
      is_private: {
        type: "boolean",
        description: "Optional flag indicating whether the issue is private. When set to true, the issue will only be visible to users with permission to view private issues. Setting this field requires the appropriate permissions in the project."
      },
      estimated_hours: {
        type: "number",
        description: "Optional estimated number of hours required to complete the issue. This value represents the total expected effort and is typically used for planning and reporting. The value must be a non-negative number."
      },
      notes: {
        type: "string",
        description: "A comment or journal entry to be added to the issue. This is used to document the reason for the update or to provide feedback to other users. Supports Redmine's textile or markdown formatting depending on server settings."
      },
      private_notes: {
        type: "boolean",
        description: "If set to true, the comment in 'notes' will only be visible to users with the 'View private notes' permission (typically developers and managers). Defaults to false."
      }
    },
    required: %w[issue_id]
  )

  class << self
    def call(server_context:, **kwargs)
      issue_id = kwargs.fetch(:issue_id)
      issue = Issue.find_by(id: issue_id)

      return error_response("could not find issue with ID #{issue_id}") unless issue
      return error_response"user has no permissions to view issue with ID #{issue_id}" unless issue.visible?
      return error_response("user has no permissions to edit issue with ID #{issue_id}") unless issue.editable?

      notes = kwargs.delete(:notes)
      private_notes = !!kwargs.delete(:private_notes)
      attrs = kwargs.except(:issue_id).compact.deep_stringify_keys

      if notes.present?
        journal = issue.init_journal(User.current, notes)
        journal.private_notes = true if private_notes
      end

      issue.safe_attributes = attrs

      if issue.save
        json_string = render_template_json server_context, "issues/show", { issue: issue }
        text_response(json_string)
      else
        error_response(issue.errors.full_messages.to_sentence)
      end
    end
  end
end