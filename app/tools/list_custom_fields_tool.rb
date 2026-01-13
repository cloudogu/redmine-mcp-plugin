class ListCustomFieldsTool < RedmineTool
  description "Lists available custom fields for a specific project."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project." },
    },
    required: [
      "project_id",
    ],
  )

  class << self
    def call(server_context:, project_id:)
      project = Project.find_by(id: project_id)
      if project.nil?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Project with ID #{project_id} not found." }], error: true)
      end

      unless project.visible?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: You do not have permission to access Project ID #{project_id}." }], error: true)
      end

      custom_fields = IssueCustomField.includes([:roles]).all.map do |cf|
        if cf.visible_by?(project, User.current)
          {
            id: cf.id,
            name: cf.name,
          }
        end
      end.compact

      MCP::Tool::Response.new([{
        type: "text",
        text: custom_fields.to_json,
      }])
    end
  end
end
