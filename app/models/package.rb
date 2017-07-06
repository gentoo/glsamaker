# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#  Copyright (C) 2017 Robin H. Johnson <robbat2@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Package model
class Package < ActiveRecord::Base
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

  # Arches (from $PORTDIR/profiles/arch.list)
  ARCHLIST_BASE = %w{alpha amd64 arm arm64 hppa ia64 m68k mips nios2 ppc ppc64 riscv s390 sh sparc x86}.freeze
  ARCHLIST_FBSD = %w{amd64-fbsd sparc-fbsd x86-fbsd}.freeze
  ARCHLIST_PREFIX = %w{ppc-aix amd64-linux arm-linux arm64-linux ppc64-linux x86-linux ppc-macos x86-macos x64-macos m68k-mint sparc-solaris sparc64-solaris x64-solaris x86-solaris x86-winnt x64-cygwin x86-cygwin}.freeze
  ARCHLIST = (ARCHLIST_BASE+ARCHLIST_FBSD+ARCHLIST_PREFIX).freeze
  ARCHLIST_REGEX = %r{(?:#{ARCHLIST.join('|')})}.freeze

  # Model properties
  belongs_to :revision
  validates :comp, :inclusion => { :in => COMP_MAP.keys }
  validates :arch, :format => { :with => /\A(\*|(#{ARCHLIST_REGEX} )*#{ARCHLIST_REGEX})\z/ }

  # Returns the comparator in the format needed for the XML
  def xml_comp
    COMP_MAP[self.comp]
  end

  def self.reverse_comp(cmp)
    COMP_MAP.invert[cmp]
  end
end
