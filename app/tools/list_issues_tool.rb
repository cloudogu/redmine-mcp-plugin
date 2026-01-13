class ListIssuesTool < RedmineTool
  description "Retrieves a list of issues based on various filters."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project to filter by." },
      tracker_id: { type: "integer", description: "The numeric ID of the tracker to filter by." },
      assigned_to_id: { type: "string", description: "The numeric ID of the assigned user, or 'me'." },
      authored_by_id: { type: "string", description: "The numeric ID of the author, or 'me'." },
      offset: { type: "integer", default: 0, description: "Pagination offset (default: 0)." },
      limit: { type: "integer", default: 100, description: "Pagination limit (default: 100)." },
    },
    required: [],
  )

  class << self
    def call(server_context:, project_id: nil, tracker_id: nil, assigned_to_id: nil, authored_by_id: nil, offset: 0, limit: 100)
      if project_id
        project = Project.find_by(id: project_id)
        if project.nil?
          return MCP::Tool::Response.new([{ type: "text", text: "Error: Project with ID #{project_id} not found." }], error: true)
        end

        unless project.visible?
          return MCP::Tool::Response.new([{ type: "text", text: "Error: You do not have permission to access Project ID #{project_id}." }], error: true)
        end
      end

      filters = {}

      if tracker_id
        filters["tracker_id"] = { :operator => "=", :values => [tracker_id] }
      end

      if assigned_to_id
        filters["assigned_to_id"] = { :operator => "=", :values => [assigned_to_id] }
      end

      if authored_by_id
        filters["author_id"] = { :operator => "=", :values => [authored_by_id] }
      end

      # Enforce reasonable limits
      limit = [limit.to_i, 100].min
      offset = [offset.to_i, 0].max

      query = IssueQuery.new(
        :name => "_",
        :project_id => project_id,
        :filters => filters,
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
