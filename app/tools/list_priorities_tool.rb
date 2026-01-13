class ListPrioritiesTool < RedmineTool
  description "Lists all active issue priorities."
  input_schema(
    properties: {
    },
    required: [],
  )

  class << self
    def call(server_context:)
      priorities = IssuePriority.active.sorted

      if priorities.empty?
        MCP::Tool::Response.new([{
          type: "text",
          text: "Error: Could not find any priorities.",
        }], error: true)
      end

      formatted_priorities = priorities.map do |p|
        {
          id: p.id,
          name: p.name,
          is_default: p.is_default
        }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: formatted_priorities.to_json,
      }])
    end
  end
end
