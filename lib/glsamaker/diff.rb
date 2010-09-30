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

require 'diff/lcs/hunk'

module Glsamaker
  # Module providing diff support
  module Diff
    module_function

    # Returns a unified diff for two strings
    # Adapted from the O'Reilly Ruby Cookbook
    def diff(str_old, str_new, format = :unified, context_lines = 3)
      str_old = str_old.split(/\r?\n/).map! { |l| l.chomp }
      str_new = str_new.split(/\r?\n/).map! { |l| l.chomp }

      output = ""
      diffs = ::Diff::LCS.diff(str_old, str_new)
      return output if diffs.empty?

      oldhunk = hunk = nil
      file_length_difference = 0
      diffs.each do |piece|
        begin
          hunk = ::Diff::LCS::Hunk.new(str_old, str_new, piece, context_lines, file_length_difference)
          next unless oldhunk

          if (context_lines > 0) and hunk.overlaps?(oldhunk)
            hunk.unshift(oldhunk)
          else
            output << oldhunk.diff(format)
          end
        ensure
          oldhunk = hunk
          output << "\n"
        end
      end

      output << oldhunk.diff(format) << "\n"
    end

  end
end