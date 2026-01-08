class RedmineTool < MCP::Tool
  class << self
    def render_template(server_context, template, vars)
      controller = server_context[:controller]

      unless controller
        return MCP::Tool::Response.new([{ type: "text", text: "Error: No controller context available." }], error: true)
      end

      vars.each do |key, value|
        controller.instance_variable_set("@#{key}".to_sym, value)
      end

      # Fake the format to json/api so Redmine's builder kicks in
      controller.params[:format] = "json"

      begin
        result = controller.render_to_string(template: template, formats: [:api])
        result.presence || "Error: Template rendered an empty response."
      rescue StandardError => e
        "Error rendering template #{template}: #{e.message}"
      end
    end
  end
end
