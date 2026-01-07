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

class McpController < ApplicationController
  # accept api key authentication
  accept_api_auth :index
  # skip CSRF tokens verification for MCP Server
  skip_before_action :verify_authenticity_token

  def index
    server = MCP::Server.new(
      name: "redmine",
      title: "Redmine MCP Server",
      version: "1.0.0",
      tools: [GreetingTool],
    )

    render(json: server.handle_json(request.body.read))
  end
end
