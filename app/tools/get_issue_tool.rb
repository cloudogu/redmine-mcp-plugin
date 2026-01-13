class GetIssueTool < RedmineTool
  description "Retrieves detailed information for a single issue by its numeric ID."
  input_schema(
    properties: {
      issue_id: { type: "integer", description: "The numeric ID of the issue to retrieve." },
    },
    required: ["issue_id"],
  )

  class << self
    def call(server_context:, issue_id:)
      begin
        issue = Issue.find(issue_id)
      rescue Exception
        return MCP::Tool::Response.new([{
          type: "text",
          text: "Error: No issue found with ID #{issue_id}."
        }], error: true)
      end

      unless issue.visible?
        return MCP::Tool::Response.new([{
          type: "text",
          text: "Error: You do not have permission to view issue ##{issue_id}."
        }], error: true)
      end

      issues = [issue]
      
      json_string = render_template server_context, "issues/index", {
        issues: issues,
        issue_count: issues.size,
        offset: 0,
        limit: 1,
      }

      MCP::Tool::Response.new([{
        type: "text",
        text: json_string,
      }])
    end
  end
end

