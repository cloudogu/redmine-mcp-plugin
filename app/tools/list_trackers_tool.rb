class ListTrackersTool < RedmineTool
  description "Lists enabled trackers for a specific project."
  input_schema(
    properties: {
      project_id: { type: "integer", description: "The numeric ID of the project." },
    },
    required: ["project_id"],
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

      trackers = project.trackers.sorted

      if trackers.empty?
        return error_response("Project with ID #{project_id} not found.")
      end

      formatted_trackers = trackers.map do |t|
        {
          id: t.id,
          name: t.name,
          default_status: t.default_status&.name
        }
      end

      text_response(formatted_trackers.to_json)
    end
  end
end
