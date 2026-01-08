class ListIssuesTool < RedmineTool
  description "List issues"
  input_schema(
    properties: {
      project_id: { type: "integer", description: "Get issues from the project with the given id" },
      tracker_id: { type: "integer", description: "Get issues from the tracker with the given id" },
      assigned_to_id: { type: "string", description: "Get issues which are assigned to the given user id. 'me' can be used instead an ID to fetch all issues from the logged in user" },
      authored_by_id: { type: "string", description: "Get issues which are authored by the given user id. 'me' can be used instead an ID to fetch all issues from the logged in user" },
      offset: { type: "integer", default: 0, description: "The number of issues to skip" },
      limit: { type: "integer", default: 100, description: "The maximum number of issues to return" },
    },
    required: [],
  )

  class << self
    def call(server_context:, project_id: nil, tracker_id: nil, assigned_to_id: nil, authored_by_id: nil, offset:, limit:)
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

      query = IssueQuery.new(
        :name => "_",
        :project_id => project_id,
        :filters => filters,
      )

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
