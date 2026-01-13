class FindUseridTool < RedmineTool
  description "Searches for a user by login, first name, or last name to retrieve their numeric ID."
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
      users = User.where("(LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(login) LIKE ?) AND id IN (SELECT user_id FROM #{Member.table_name} WHERE project_id IN (?))",
                         "%#{query.downcase}%", "%#{query.downcase}%", "%#{query.downcase}%", user.visible_project_ids)

      if users.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any user matching '#{query}'.",
               }], error: true)
      end

      mapped_users = users.map do |user|
        { id: user.id,
          login: user.login,
          firstname: user.firstname,
          lastname: user.lastname }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mapped_users.to_json,
      }])
    end
  end
end
