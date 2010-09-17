module Admin::UsersHelper
  def access_string(lvl)
    case lvl
    when 0
      "Contributor"
    when 1
      "Padawan"
    when 2
      "Full member"
    when 3
      "Confidential member"
    end
  end
  
  def access_list
    [0, 1, 2, 3].map{|x| [access_string(x), x]}
  end
end
