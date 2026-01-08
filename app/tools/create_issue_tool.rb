class CreateIssueTool < RedmineTool
  description "Create an issue."
  input_schema(
    properties: {
      project_id: { type: "integer" },
      tracker_id: { type: "integer" },
      status_id: { type: "integer" },
      priority_id: { type: "integer" },
      subject: { type: "string" },
      description: { type: "string" },

    },
    required: ["project_id", "tracker_id", "subject"],
  )

  class << self
    def call(server_context:, project_id:, tracker_id:, status_id: nil, priority_id: nil, subject:, description: nil)
      user = User.current

      project = Project.find_by_id(project_id)
      return error("Unknown project") unless project

      unless user.allowed_to?(:add_issues, project, :global => true)
        return error("User not allowed to project")
      end

      tracker = Tracker.find_by_id(tracker_id)
      return error("Unknown tracker") unless tracker

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
        MCP::Tool::Response.new([{
          type: "text",
          text: {
            id: issue.id,
            tracker: issue.tracker.to_s,
            subject: issue.subject,
          }.to_json,
        }])
      else
        error(issue.errors.full_messages)
      end
    end
  end
end