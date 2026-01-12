class FindTrackeridTool < RedmineTool
  description "Find the id for a tracker"
  input_schema(
    properties: {
      query: { type: "string", description: "The search string to find a specific tracker (e.g., 'Bug', 'Feature', 'Support'). Use this to find the numeric ID of a tracker." },
    },
    required: ["query"],
  )

  class << self
    def call(server_context:, query:)
      query.strip!

      trackers = Tracker.where("LOWER(name) LIKE ?", "%#{query.downcase}%")

      if trackers.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any trackers matching '#{query}'.",
               }], error: true)
      end

      mapped = trackers.map do |t|
        { id: t.id, name: t.name }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mapped.to_json,
      }])
    end
  end
end
