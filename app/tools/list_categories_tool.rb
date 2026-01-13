class ListCategoriesTool < RedmineTool
  description "Lists available issue categories for a specific project."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project." },
    },
    required: ["project_id"],
  )

  class << self
    def call(server_context:, project_id:)
      project = Project.find_by(id: project_id)

      unless project
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Project with ID #{project_id} not found." }], error: true)
      end

      unless project.visible?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: You do not have permission to access Project ID #{project_id}." }], error: true)
      end

      categories = project.issue_categories

      if categories.empty?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: No categories found for project ID #{project_id}." }], error: true)
      end
      
      formatted_categories = categories.map do |s|
        {
          id: s.id,
          name: s.name,
          assigned_to_user_id: s.assigned_to_id
        }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: formatted_categories.to_json,
      }])
    end
  end
end
