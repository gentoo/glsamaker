# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

require 'glsamaker/helpers'

class CVE < ActiveRecord::Base
  has_many :references, :class_name => "CVEReference"
  has_many :comments, :class_name => "CVEComment"
  has_and_belongs_to_many :cpes, :class_name => "CPE"
  
  def to_s
    str = "#{self.cve_id} #{"(http://nvd.nist.gov/nvd.cfm?cvename=%s):" % self.cve_id}\n"
    str += "  " + Glsamaker::help.word_wrap(self.summary, 78).gsub(/\n/, "\n  ")
  end
end
