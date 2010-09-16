module ActionView
  module TemplateHandlers
    class BuilderOptions
      cattr_accessor :margin, :indent
    end
  end
end

module ActionView
  module TemplateHandlers
    class Builder < TemplateHandler

      def compile(template)
        "_set_controller_content_type(Mime::XML);" +
          "xml = ::Builder::XmlMarkup.new(" +
          ":indent => #{ActionView::TemplateHandlers::BuilderOptions.indent}, " +
          ":margin => #{ActionView::TemplateHandlers::BuilderOptions.margin});" +
          "self.output_buffer = xml.target!;" +
          template.source +
          ";xml.target!;"
      end
    end
  end
end

ActionView::TemplateHandlers::BuilderOptions.margin = 0
ActionView::TemplateHandlers::BuilderOptions.indent = 2