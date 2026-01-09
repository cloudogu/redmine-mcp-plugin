class McpController < ApplicationController
  # accept api key authentication
  accept_api_auth :index
  # skip CSRF tokens verification for MCP Server
  skip_before_action :verify_authenticity_token

  # Import CustomFieldsHelper so render_api_custom_values is available in views
  helper :custom_fields

  def index
    @logger = Rails.logger

    config = MCP::Configuration.new(
      protocol_version: "2025-06-18",
      exception_reporter: ->(e, ctx) {
        @logger.error("MCP Error: #{e.message}")
        @logger.error("Root cause: #{e.cause.message}") if e.cause
        @logger.debug(ctx.inspect)
      },
      instrumentation_callback: ->(data) {
        @logger.info("MCP: #{data[:method]} (#{data[:duration]}s)")
      },
    )

    server = MCP::Server.new(
      name: "redmine",
      title: "Redmine MCP Server",
      version: "1.0.0",
      tools: [MeTool, ListIssuesTool, FindUseridTool, FindProjectidTool, FindTrackeridTool, FindStatusidTool, FindPriorityidTool],
      server_context: { controller: self },
      configuration: config,
    )

    render(json: server.handle_json(request.body.read))
  end
end
