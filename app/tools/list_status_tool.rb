class ListStatusTool < RedmineTool
  description "Lists available issue statuses for a specific tracker."
  input_schema(
    properties: {
      tracker_id: { type: "integer", description: "The numeric ID of the tracker." },
    },
    required: ["tracker_id"],
  )

  class << self
    def call(server_context:, tracker_id:)
      tracker = Tracker.find_by(id: tracker_id)

      unless tracker
        return error_response("Tracker with ID #{tracker_id} not found.")
      end

      statuses = tracker.issue_statuses
      json = render_template(server_context, "issue_statuses/index", {
        issue_statuses: statuses,
      })

      text_response(json)
    end
  end
end
