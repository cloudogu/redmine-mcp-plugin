class FindPriorityidTool < RedmineTool
  description "Find the id for an issue priority"
  input_schema(
    properties: {
      query: { type: "string", description: "The search string to find a specific issue priority (e.g., 'Low', 'Normal', 'High', 'Urgent'). Use this to find the numeric ID of a priority." },
    },
    required: ["query"],
  )

  class << self
    def call(server_context:, query:)
      priorities = IssuePriority.where("LOWER(name) LIKE ?", "%#{query.downcase}%")

      if priorities.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any priorities matching '#{query}'.",
               }], error: true)
      end

      mapped = priorities.map do |p|
        { id: p.id, name: p.name }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mapped.to_json,
      }])
    end
  end
end
