# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#  Copyright (C) 2006-2007 Jean-Philippe Lang
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
   # Same as Rails' simple_format helper without using paragraphs
   def simple_format_without_paragraph(text)
     text.to_s.
       gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
       gsub(/\n\n+/, "<br /><br />").          # 2+ newline  -> 2 br
       gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')  # 1 newline   -> br
   end
   
   
end
