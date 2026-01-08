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
        description: "Optional issue status ID. If omitted, tracker's default issue status will be used."
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
      }
    },
    required: %w[project_id tracker_id subject]
  )

  class << self
    def call(server_context:, project_id:, tracker_id:, status_id: nil, priority_id: nil, subject:, description: nil)
      user = User.current

      project = Project.find_by_id(project_id)
      return error_response("could not find project with ID #{project_id}") unless project

      unless user.allowed_to?(:add_issues, project, :global => true)
        return error_response("user not allowed to add issues to project with ID #{project_id}")
      end

      tracker = Tracker.find_by_id(tracker_id)
      return error_response("could not find tracker with ID #{tracker_id}") unless tracker

      issue = Issue.new(
        project: project,
        author: user,
        subject: subject,
        description: description,
        tracker: tracker,
      )

      if status_id.present?
        issue.status_id = status_id
      else
        issue.status = tracker.default_status
      end

      if priority_id.present?
        issue.priority_id = priority_id
      else
        issue.priority = IssuePriority.default_or_middle
      end

      if issue.save
        json_string = render_template server_context, "issues/show", { issue: issue }

        MCP::Tool::Response.new([{
          type: "text",
          text: json_string
        }])
      else
        error_response(issue.errors.full_messages.join())
      end
    end
  end
end