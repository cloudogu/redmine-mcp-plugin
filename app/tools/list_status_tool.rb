class ListStatusTool < RedmineTool
  description "Lists available issue statuses for a specific tracker."
  input_schema(
    properties: {
      tracker_id: { type: "integer", description: "The numeric ID of the tracker." },
    },
    required: ["tracker_id"],
  )

  class << self
    def call(server_context:, tracker_id:)
      tracker = Tracker.find_by(id: tracker_id)

      unless tracker
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Tracker with ID #{tracker_id} not found." }], error: true)
      end

      statuses = tracker.issue_statuses

      if statuses.empty?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: No statuses found for tracker ID #{tracker_id}." }], error: true)
      end
        
      formatted_statuses = statuses.map do |s|
        {
          id: s.id,
          name: s.name,
          is_closed: s.is_closed
        }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: formatted_statuses.to_json,
      }])
    end
  end
end
