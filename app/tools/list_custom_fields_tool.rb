class ListCustomFieldsTool < RedmineTool
  description "Lists available custom fields for a specific project."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project." },
    },
    required: [
      "project_id",
    ],
  )

  class << self
    def call(server_context:, project_id:)
      project = Project.find_by(id: project_id)

      if project.nil?
        return error_response("Project with ID #{project_id} not found.")
      end

      unless project.visible?
        return error_response("You do not have permission to access Project ID #{project_id}.")
      end

      custom_fields = IssueCustomField.includes([:roles]).all.map do |cf|
        if cf.visible_by?(project, User.current)
          {
            id: cf.id,
            name: cf.name,
          }
        end
      end.compact

      if custom_fields.empty?
        return error_response("Could not find any custom fields for project ID: #{project_id}")
      end

      text_response(custom_fields.to_json)
    end
  end
end
