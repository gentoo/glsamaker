module CveHelper
  
  def make_js_safe(str)
    str.gsub("'", "\'")
  end
end
