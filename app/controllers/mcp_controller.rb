class GreetingTool < MCP::Tool
  description "A tool that greets the user."
  input_schema(
    properties: {
      user: { type: "string" },
    },
    required: ["user"]
  )

  class << self
    def call(user:, server_context:)
      MCP::Tool::Response.new([{
        type: "text",
        text: "Hello #{user}",
      }])
    end
  end
end

class MeTool < MCP::Tool
  description "Get details about the currently authenticated user."
  input_schema(
    properties: {},
    required: []
  )

  class << self
    def call(server_context:)
      controller = Thread.current[:mcp_controller]
      
      unless controller
        return MCP::Tool::Response.new([{ type: "text", text: "Error: No controller context available." }])
      end

      user = User.current
      # Set @user instance variable on the controller so the view can access it
      controller.instance_variable_set(:@user, user)

      # Fake the format to json/api so Redmine's builder kicks in
      controller.params[:format] = 'json'

      json_string = ""
      begin
        # Render the existing Redmine view 'app/views/my/account.api.rsb'
        json_string = controller.render_to_string(template: 'my/account', formats: [:api])
      rescue => e
        Rails.logger.error "MeTool Rendering Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        json_string = "Error rendering view: #{e.message}"
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: json_string
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
    Thread.current[:mcp_controller] = self

    server = MCP::Server.new(
      name: "redmine",
      title: "Redmine MCP Server",
      version: "1.0.0",
      tools: [GreetingTool, MeTool],
    )

    render(json: server.handle_json(request.body.read))
  ensure
    Thread.current[:mcp_controller] = nil
  end
end
