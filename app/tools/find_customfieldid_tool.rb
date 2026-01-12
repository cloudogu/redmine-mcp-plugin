class FindCustomfieldidTool < RedmineTool
  description "Find the id for a custom field"
  input_schema(
    properties: {
      query: { type: "string", description: "The search string to find a specific custom field by name. Use this to find the numeric ID of a custom field." },
    },
    required: ["query"],
  )

  class << self
    def call(server_context:, query:)
      fields = CustomField.where("LOWER(name) LIKE ?", "%#{query.downcase}%").select { |f| f.visible_by?(User.current) }

      if fields.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any custom fields matching '#{query}'.",
               }], error: true)
      end

      mapped = fields.map do |f|
        { id: f.id, name: f.name, type: f.type }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mapped.to_json,
      }])
    end
  end
end
