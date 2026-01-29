class ListIssuesTool < RedmineTool
  description <<~DESCRIPTION
    Retrieves a list of issues based on various filters.

    This operation requires Redmine identifiers (projects, trackers, status, priorities, category, assigned_to, custom fields).
    Identifiers are usually numeric IDs, but some IDs in this tool are of type string nonetheless to allow special values such as "me". 
    When only names or labels are known, use the provided List/Find tools to resolve them to IDs 
    before creating or updating issues. Do not guess IDs, ask for more information, if necessary.

    Use read and list tools to discover data first; use this tool only once required identifiers are known.
  DESCRIPTION
  input_schema(
    properties: {
      project_id: { type: "integer", description: "Project identifier. The numeric ID as an integer of the project to filter by." },
      tracker_id: { type: "integer", description: "Tracker identifier. The numeric ID as an integer of the tracker to filter by." },
      assigned_to_id: {
        type: "string",
        description: "Assigned user identifier. Provide the numeric Redmine user ID as a string, or the literal value 'me' to refer to the currently authenticated user."
      },
      authored_by_id: {
        type: "string",
        description: "Author identifier. Provide the numeric Redmine user ID as a string, or the literal value 'me' to refer to the currently authenticated user."
      },
      status_ids: {
        type: "array",
        description: "Filter by status IDs. A list of specific numeric IDs as integers.",
        items: { type: "integer" }
      },
      priority_ids: {
        type: "array",
        description: "Filter by priority IDs. A list of specific numeric IDs as integers.",
        items: { type: "integer" }
      },
      category_ids: {
        type: "array",
        description: "Filter by category IDs. A list of specific numeric IDs as integers.",
        items: { type: "integer" }
      },
      custom_fields: {
        type: "array",
        description: "List of custom field filters to apply.",
        items: {
          type: "object",
          properties: {
            id: {
              type: "integer",
              description: "ID of the Redmine custom field.",
            },
            value: {
              type: "string",
              description: "Value to assign to the custom field.",
            },
          },
          required: %w[id value],
        },
      },
      offset: { type: "integer", default: 0, description: "Pagination offset (default: 0)." },
      limit: { type: "integer", default: 20, description: "Pagination limit (default: 20)." },
    },
    required: [],
  )

  class << self
    def call(server_context:, project_id: nil, tracker_id: nil, assigned_to_id: nil, priority_ids: nil, category_ids: nil, authored_by_id: nil, status_ids: nil, custom_fields: nil, offset: 0, limit: 20)
      if project_id
        project = Project.find_by(id: project_id)
        if project.nil?
          return error_response("Project with ID #{project_id} not found.")
        end

        unless project.visible?
          return error_response("You do not have permission to access Project ID #{project_id}.")
        end
      end

      filters = {}

      if tracker_id
        filters["tracker_id"] = { :operator => "=", :values => [tracker_id] }
      end

      if assigned_to_id
        filters["assigned_to_id"] = { :operator => "=", :values => [assigned_to_id] }
      end

      if authored_by_id
        filters["author_id"] = { :operator => "=", :values => [authored_by_id] }
      end

      if status_ids.present?
        filters["status_id"] = { :operator => "=", :values => status_ids.map(&:to_s) }
      end

      if priority_ids.present?
        filters["priority_id"] = { :operator => "=", :values => priority_ids.map(&:to_s) }
      end

      if category_ids.present?
        filters["category_id"] = { :operator => "=", :values => category_ids.map(&:to_s) }
      end

      if custom_fields
        custom_fields.each do |cf|
          custom_field = IssueCustomField.find_by(id: cf[:id])
          unless custom_field
            return error_response("The custom field with id #{cf[:id]} was not found")
          end
          unless custom_field.is_filter?
            return error_response("The custom field with id #{cf[:id]} is not filterable")
          end
          filters["cf_#{cf[:id]}"] = { :operator => "=", :values => [cf[:value]] }
        end
      end

      if offset < 0
        return error_response("Offset must be a non-negative integer.")
      end

      if limit > 100
        return error_response("Limit cannot exceed 100.")
      end

      query = IssueQuery.new(
        :name => "_",
        :project_id => project_id,
        :filters => filters,
      )

      unless query.valid?
        return error_response("Invalid issue query parameters.")
      end

      issue_count = query.issue_count
      issues = query.issues(offset: offset, limit: limit)

      json_string = render_template server_context, "issues/index", {
        issues: issues,
        issue_count: issue_count,
        offset: offset,
        limit: limit,
      }

      return text_response(json_string)
    end
  end
end
