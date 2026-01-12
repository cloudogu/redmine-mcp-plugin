class FindProjectidTool < RedmineTool
  description "Find the id for a project via its name or identifier"
  input_schema(
    properties: {
      query: { type: "string", description: "The search string for the project's name or its unique identifier (slug). Use this to find the numeric ID of a project." },
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

      mappedProjects = projects.map do |project|
        {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
        }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mappedProjects.to_json,
      }])
    end
  end
end
