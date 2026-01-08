class ListIssuesTool < RedmineTool
  description "List issues"
  input_schema(
    properties: {
      project_id: { type: "integer" },
      offset: { type: "integer", default: 0 },
      limit: { type: "integer", default: 100 },
    },
    required: [],
  )

  class << self
    def call(server_context:, project_id: nil, offset:, limit:)
      if project_id
        project = Project.find_by(id: project_id)
        if project.nil?
          return MCP::Tool::Response.new([{ type: "text", text: "Error: Project with ID #{project_id} not found." }], error: true)
        end

        unless project.visible?
          return MCP::Tool::Response.new([{ type: "text", text: "Error: You do not have permission to access Project ID #{project_id}." }], error: true)
        end
      end

      # Enforce reasonable limits
      limit = [limit.to_i, 100].min
      offset = [offset.to_i, 0].max

      query = IssueQuery.new(
        :name => "_",
        # if project_id does not exist, it will list issues from all projects
        :project_id => project_id,
      )

      unless query.valid?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Invalid issue query parameters." }], error: true)
      end

      issue_count = query.issue_count
      issues = query.issues(offset: offset, limit: limit)

      json_string = render_template server_context, "issues/index", {
        issues: issues,
        issue_count: issue_count,
        offset: offset,
        limit: limit,
      }

      MCP::Tool::Response.new([{
        type: "text",
        text: json_string,
      }])
    end
  end
end
