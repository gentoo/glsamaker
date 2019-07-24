module Admin::TemplatesHelper
  # Generates a list of targets
  def target_list
    GLSAMAKER_TEMPLATE_TARGETS.map{|x| [x.titleize, x]}
  end
end
