# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

module Glsamaker
  module XML
    module_function
    def indent(xml, options = {:indent => 2})
      command = GLSAMAKER_XMLINDENT
      raise "xmlindent either does not exist or is not executable." unless File.executable? command
      
      command += " -i#{Integer options[:indent]}" if options.has_key? :indent
      command += " -l#{Integer options[:maxcols]}" if options.has_key? :maxcols

      # \r\n will make problems while converting
      xml.gsub!("\r", "")

      IO.popen(command, 'r+') do |io|
        io.write xml
        io.close_write
        io.read
      end
    end
  end
end
