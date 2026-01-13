class FindProjectidTool < RedmineTool
  description "Searches for a project by name or identifier to retrieve its numeric ID."
  input_schema(
    properties: {
      query: { type: "string", description: "The partial or full name, or unique identifier (slug) of the project." },
    },
    required: ["query"],
  )

  class << self 
    def call(server_context:, query:)
      query.strip!
      user = User.current

      projects = Project.where("(LOWER(name) LIKE ? OR LOWER(identifier) LIKE ?) AND id IN (?)",
        "%#{query.downcase}%", "%#{query.downcase}%", user.visible_project_ids)

      if projects.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any projects matching '#{query}'.",
               }], error: true)
      end

      mapped_projects = projects.map do |project|
        {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
        }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mapped_projects.to_json,
      }])
    end
  end
end
