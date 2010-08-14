# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

class CVE < ActiveRecord::Base
  has_many :references, :class_name => "CVEReference"
  has_many :comments, :class_name => "CVEComment"
  has_and_belongs_to_many :cpes, :class_name => "CPE"
end
