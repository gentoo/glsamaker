# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.
#

class String
  def purple
    ansi 35
  end
  
  def red
    ansi 31
  end
  
  def green
    ansi 32
  end
  
  def bold
    ansi 1
  end

  private
  def ansi(code)
    code = Integer(code)
    "\033[1;#{code}m#{self}\033[0m"
  end
end
