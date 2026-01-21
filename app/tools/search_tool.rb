class SearchTool < RedmineTool
  description  <<~DESC
    Full-text search in Redmine using a plain-text query.

    Query matching is case-insensitive substring matching on whitespace-separated terms (AND by default).
    No advanced query syntax is supported (no wildcards, quoting/negation, regex, or field operators like field:value).
    Narrow results using the structured parameters (project_id, scope, titles_only, open_issues, etc.), not by encoding filters in the query string.
  DESC
  input_schema(
    properties: {
      query: { type: "string", description: "Plain-text search terms." },
      project_id: { type: "integer", description: "Restrict search to a specific project ID" },
      scope: {
        type: "array",
        items: { type: "string" },
        description: "Specific types to search (e.g., 'issues', 'news', 'documents', 'changesets', 'wiki-pages', 'messages', 'projects'). If omitted, searches all types."
      },
      all_words: { type: "boolean", default: true, description: "If true, all query terms must match; if false, any term may match. Default: true." },
      titles_only: { type: "boolean", description: "If true, search only titles/subjects. Default: false." },
      attachments: { type: "boolean", description: "If true, include attachment content in search (if supported). Default: false." },
      open_issues: { type: "boolean", description: "If searching issues, restrict to open issues. Default: false." },
      limit: { type: "integer", default: 20, description: "Number of results to return. Maximum is 100. Default: 20." },
      offset: { type: "integer", default: 0, description: "Offset for pagination. Default: 0." }
    },
    required: ["query"]
  )

  class << self
    def call(server_context:, query:, project_id: nil, scope: nil, all_words: true, titles_only: false, attachments: false, open_issues: false, limit: 20, offset: 0)
      if limit > 100 
        return error_response("The given limit exceeded the allowed maximum of 100")
      end

      query.strip!
      
      user = User.current

      project_to_search = nil
      if project_id
        project = Project.find_by_id(project_id)
        return error_response("Project with ID #{project_id} not found") unless project
        
        unless project.visible?(user)
          return error_response("You do not have permission to access Project ID #{project_id}.")
        end
        project_to_search = project
      end

      available_search_types = Redmine::Search.available_search_types.dup

      # if project search is active, we need to remove it from the object types since we can set it now explicitly in the fetchers query
      if project_to_search.is_a?(Project)
        available_search_types.delete('projects')
        available_search_types = available_search_types.select {|o| user.allowed_to?(:"view_#{o}", project_to_search)}
      end

      final_scope = if scope.present?
                      scope.select { |t| available_search_types.include?(t) }
                    else
                      available_search_types
                    end

      if final_scope.empty?
         return error_response("No valid search scope found.")
      end

      fetcher = Redmine::Search::Fetcher.new(
        query, user, final_scope, project_to_search,
        :all_words => all_words,
        :titles_only => titles_only,
        :attachments => attachments ? '1' : '0',
        :open_issues => open_issues,
        :cache => false
      )

      result_count = fetcher.result_count
      results = fetcher.results(offset, limit)

      json_string = render_template_json(server_context, "search/index", {
        results: results,
        result_count: result_count,
        offset: offset,
        limit: limit
      })
      
      text_response(json_string)
    end
  end
end

