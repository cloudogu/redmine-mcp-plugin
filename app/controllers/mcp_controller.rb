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
      tools: [
        MeTool,
        SearchTool,
        FindUseridTool,
        FindProjectidTool,
        GetIssueTool,
        CreateIssueTool,
        UpdateIssueTool,
        ListIssuesTool,
        ListCustomFieldsTool,
        ListTrackersTool,
        ListStatusTool,
        ListPrioritiesTool,
        ListCategoriesTool,
      ],
      server_context: { controller: self },
      configuration: config,
      instructions: <<~INSTRUCTIONS
        This MCP server provides access to a Redmine system.

        “Issue” and “Ticket” are synonymous and both refer to a Redmine issue.

        Most operations require Redmine identifiers (projects, users, trackers, statuses, priorities, categories, custom fields).
        Identifiers are usually numeric IDs, but some tools accept IDs as strings to allow special values such as "me".
        When only names or labels are known, use the provided List/Find tools to resolve them to IDs before creating or updating issues.
        Do not guess IDs, ask for more information, if necessary.

        Use read and list tools to discover data first; use create and update tools only once required identifiers are known.
      INSTRUCTIONS
    )

    render(json: server.handle_json(request.body.read))
  end
end
