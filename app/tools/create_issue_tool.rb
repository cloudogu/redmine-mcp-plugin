class CreateIssueTool < RedmineTool
  description "Create an issue"
  input_schema(
    properties: {
      project_id: {
        type: "integer",
        description: "Numeric Redmine project ID in which the issue will be created. This must be a project where the authenticated user has permission to add issues."
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
      }
    },
    required: %w[project_id tracker_id subject]
  )

  class << self
    def call(server_context:, **kwargs)
      user = User.current

      project_id = kwargs[:project_id]

      project = Project.find_by_id(project_id)
      return error_response("could not find project with ID #{project_id}") unless project

      unless user.allowed_to?(:add_issues, project, :global => true)
        return error_response("user not allowed to add issues to project with ID #{project_id}")
      end

      issue = Issue.new(
        author: user
      )

      issue.safe_attributes=(kwargs.compact)

      if issue.save
        json_string = render_template_json server_context, "issues/show", { issue: issue }
        text_response(json_string)
      else
        error_response(issue.errors.full_messages.join(","))
      end
    end
  end
end