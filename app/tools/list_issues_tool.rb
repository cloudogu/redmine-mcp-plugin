class ListIssuesTool < RedmineTool
  description "List issues"
  input_schema(
    properties: {
      project_id: { type: "integer" },
      tracker_id: { type: "integer" },
      offset: { type: "integer", default: 0 },
      limit: { type: "integer", default: 100 },
    },
    required: [],
  )

  class << self
    def call(server_context:, project_id: nil, tracker_id: nil, offset:, limit:)
      filters = {}

      if tracker_id
        filters['tracker_id'] = {:operator => '=', :values => [tracker_id]}
      end

      query = IssueQuery.new(
        :name => "_",
        :project_id => project_id,
        :filters => filters
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
