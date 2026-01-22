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

      json_string = render_template server_context, "my/account", { user: User.current }
      if json_string.is_a?(String)
        data = JSON.parse(json_string)
        data["user"]&.delete("api_key")
        json_string = data.to_json
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: json_string,
      }])
    end
  end
end
