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

require 'diff'

module Glsamaker
  # Module providing diff support
  module Diff
    
    # DiffContainer represents a set of diffs
    class DiffContainer
      attr_reader :diff, :words, :content_to, :content_from

      def initialize(content_to, content_from)
        @content_to = content_to || ""
        @content_from = content_from || ""
        @words = @content_to.split(/(\s+)/)
        @words = @words.select {|word| word != ' '}
        words_from = @content_from.split(/(\s+)/)
        words_from = words_from.select {|word| word != ' '}    
        @diff = words_from.diff @words
      end
    end
  end
end