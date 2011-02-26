# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Encapsulates a comment to a Bug
module Bugzilla
  class Comment
    attr_reader :author, :text, :date
  
    def initialize(by, text, date)
      @author = by
      @text = text
      @date = Time.parse(date)
    end
  end
end
