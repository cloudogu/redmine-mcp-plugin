class RedmineTool < MCP::Tool
  class << self
    def render_template(server_context, template, vars)
      controller = server_context[:controller]

      unless controller
        return MCP::Tool::Response.new([{ type: "text", text: "Error: No controller context available." }])
      end

      vars.each do |key, value|
        controller.instance_variable_set("@#{key}".to_sym, value)
      end

      # Fake the format to json/api so Redmine's builder kicks in
      controller.params[:format] = "json"

      return controller.render_to_string(template: template, formats: [:api])
    end
  end
end

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

class McpController < ApplicationController
  # accept api key authentication
  accept_api_auth :index
  # skip CSRF tokens verification for MCP Server
  skip_before_action :verify_authenticity_token

  # Import CustomFieldsHelper so render_api_custom_values is available in views
  helper :custom_fields

  def index
    server = MCP::Server.new(
      name: "redmine",
      title: "Redmine MCP Server",
      version: "1.0.0",
      tools: [MeTool],
      server_context: { controller: self },
    )

    render(json: server.handle_json(request.body.read))
  ensure
    Thread.current[:mcp_controller] = nil
  end
end
