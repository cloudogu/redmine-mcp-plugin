class FindUseridTool < RedmineTool
  description "Searches for a user by login, first name, or last name to retrieve their numeric ID. This is an exclusive or operation, so only one of the three parameters can be specified."
  input_schema(
    properties: {
      query: { type: "string", description: "The search string matching the user's login, first name, or last name." },
    },
    required: ["query"],
  )

  class << self
    def call(server_context:, query:)
      query.strip!
      user = User.current

      users = User
                .where(id: Member.where(project_id: user.visible_project_ids).select(:user_id))
                .like(query)

      if users.empty?
        return error_response("Could not find any user matching '#{query}'.")
      end

      mapped_users = users.map do |u|
        { id: u.id,
          login: u.login,
          firstname: u.firstname,
          lastname: u.lastname }
      end

      text_response(mapped_users.to_json)
    end
  end
end
