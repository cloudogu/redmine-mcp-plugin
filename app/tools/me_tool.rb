class MeTool < RedmineTool
  description "Retrieves details about the currently authenticated user (me)."
  input_schema(
    properties: {},
    required: [],
  )

  class << self
    def call(server_context:)
      if User.current.anonymous?
        return MCP::Tool::Response.new([{ type: "text", text: "Error: Tried to access account details without login." }], error: true)
      end

      my_user = User.current
      my_user.attributes.delete("api_key")
      json_string = render_template server_context, "my/account", { user: my_user }

      MCP::Tool::Response.new([{
        type: "text",
        text: json_string,
      }])
    end
  end
end
