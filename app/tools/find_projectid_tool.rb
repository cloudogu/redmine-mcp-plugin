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

      projects = Project.visible.like(query)
                         
      mapped_projects = projects.map do |project|
        {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
        }
      end

      text_response(mapped_projects.to_json)
    end
  end
end
