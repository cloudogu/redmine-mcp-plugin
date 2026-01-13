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
        return error_response("Could not find any priorities.")
      end

      formatted_priorities = priorities.map do |p|
        {
          id: p.id,
          name: p.name,
          is_default: p.is_default
        }
      end

      text_response(formatted_priorities.to_json)
    end
  end
end
