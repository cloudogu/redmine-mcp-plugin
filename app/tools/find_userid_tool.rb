class FindUseridTool < RedmineTool
  description "Find the id for a user"
  input_schema(
    properties: {
      query: { type: "string", description: "A part of the user's login, first name or last name" },
    },
    required: ["query"],
  )

  class << self
    def call(server_context:, query:)
      users = User.where("LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(login) LIKE ?",
                         "%#{query.downcase}%", "%#{query.downcase}%", "%#{query.downcase}%")

      if users.empty?
        return MCP::Tool::Response.new([{
                 type: "text",
                 text: "Could not find any user matching '#{query}'.",
               }])
      end

      mappedUsers = users.map do |user|
        { id: user.id,
          login: user.login,
          firstname: user.firstname,
          lastname: user.lastname }
      end

      MCP::Tool::Response.new([{
        type: "text",
        text: mappedUsers.to_json,
      }])
    end
  end
end
