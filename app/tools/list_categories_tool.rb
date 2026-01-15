class ListCategoriesTool < RedmineTool
  description "Lists available issue categories for a specific project."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project." },
    },
    required: ["project_id"],
  )

  class << self
    def call(server_context:, project_id:)
      project = Project.find_by(id: project_id)

      unless project
        return error_response("Project with ID #{project_id} not found.")
      end

      unless project.visible?
        return error_response("You do not have permission to access Project ID #{project_id}.")
      end

      categories = project.issue_categories.includes([:assigned_to])

      json = render_template(server_context, "issue_categories/index", {
        categories: categories,
      })

      text_response(json)
    end
  end
end
