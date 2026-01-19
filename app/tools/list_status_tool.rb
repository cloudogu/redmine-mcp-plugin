class ListStatusTool < RedmineTool
  description "Retrieves a list of all available issue statuses (e.g., New, In Progress, Resolved)."\
    "Use this tool to discover the correct numeric 'status_id' required for filtering issue searches"\
    "or for updating an issue's status. It provides both the ID and the display name for each status."

  class << self
    def call(server_context:)
      statuses = IssueStatus.sorted.to_a
      json = render_template_json(server_context, "issue_statuses/index", {issue_statuses: statuses})
      text_response(json)
    end
  end
end
