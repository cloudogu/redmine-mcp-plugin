class ListTrackersTool < RedmineTool
  description "Lists enabled trackers for a specific project."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project." },
    },
    required: ["project_id"],
  )

  class << self
    def call(server_context:, project_id:)
      project = Project.find_by(id: project_id)

      if project.nil?
        return MCP::Tool::Response.new([{
          type: "text",
          text: "Error: Project with ID #{project_id} not found."
        }],
          error: true)
      end

      unless project.visible?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: You do not have permission to access Project ID #{project_id}." }], error: true)
      end

      trackers = project.trackers.sorted

      if trackers.empty?
        return MCP::Tool::Response.new([{
          type: "text",
          text: "Error: Project with ID #{project_id} not found."
        }],
          error: true)
      end

      formatted_trackers = trackers.map do |t|
        {
          id: t.id,
          name: t.name,
          default_status: t.default_status&.name
        }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: formatted_trackers.to_json,
      }])
    end
  end
end
