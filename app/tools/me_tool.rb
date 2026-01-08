class MeTool < RedmineTool
  description "Get details about the currently authenticated user."
  input_schema(
    properties: {},
    required: [],
  )

  class << self
    def call(server_context:)
      json_string = render_template server_context, "my/account", { user: User.current }

      MCP::Tool::Response.new([{
        type: "text",
        text: json_string,
      }])
    end
  end
end
