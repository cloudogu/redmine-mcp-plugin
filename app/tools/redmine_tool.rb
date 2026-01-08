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

  def error(content)
    MCP::Tool::Response.new(
      [{
         type: "text",
         text: content.to_json
       }],
      error: true
    )
  end
end
