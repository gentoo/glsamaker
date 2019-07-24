# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

module Glsamaker
  class Spelling
    class << self
      def init
        dic = File.join(Rails.root, 'vendor', 'dictionaries', 'en_US.dic')
        aff = File.join(Rails.root, 'vendor', 'dictionaries', 'en_US.aff')

        @runspell = Runspell.new(aff, dic)
      end

      def check(word)
        init if @runspell.nil?
        @runspell.check(word)
      end

      def suggest(word)
        init if @runspell.nil?
        @runspell.suggest(word)
      end

      # Checks a string for spelling, <tt>before_marker</tt> and <tt>after_maker</tt> are put around the misspelled words
      def check_string(string, before_marker, after_marker)
        result = []
        string.split(/\b/).each do |word|
          if word =~ /^[\s,.-:(){}\[\]<>]*$/
            result << word
          elsif check(word)
             result << word
          else
             result << before_marker.html_safe + word + after_marker.html_safe
          end
        end

        result.join
      end
    end
  end
end
