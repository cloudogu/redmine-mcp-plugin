class ListPrioritiesTool < RedmineTool
  description "Lists all active issue priorities."
  input_schema(
    properties: {},
    required: [],
  )

  class << self
    def call(server_context:)
      priorities = IssuePriority.active.sorted

      json = render_template(server_context, "enumerations/index", {
        klass: IssuePriority,
        enumerations: priorities,
      })
      text_response(json)
    end
  end
end
