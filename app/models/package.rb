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

# Package model
class Package < ActiveRecord::Base
  belongs_to :revision
  validates :comp, :inclusion => { :in => %w[>= > = <= < *< *<= *> *>=] }

  # Mapping XML comparators to internally used ones
  COMP_MAP = {
      '>=' => 'ge',
      '>'  => 'gt',
      '='  => 'eq',
      '<=' => 'le',
      '<'  => 'lt',
      '*<' => 'rlt',
      '*<=' => 'rle',
      '*>' => 'rgt',
      '*>=' => 'rge'
    }.freeze

  # Returns the comparator in the format needed for the XML
  def xml_comp
    COMP_MAP[self.comp]
  end

  def self.reverse_comp(cmp)
    COMP_MAP.invert[cmp]
  end
end
