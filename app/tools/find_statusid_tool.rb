class FindStatusidTool < RedmineTool
  description "Find the id for an issue status"
  input_schema(
    properties: {
      query: { type: "string", description: "A part of the status name" },
    },
    required: ["query"],
  )

  class << self
    def call(server_context:, query:)
      statuses = IssueStatus.where("LOWER(name) LIKE ?", "%#{query.downcase}%")

      if statuses.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any issue statuses matching '#{query}'.",
               }], error: true)
      end

      mapped = statuses.map do |s|
        { id: s.id, name: s.name }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mapped.to_json,
      }])
    end
  end
end
