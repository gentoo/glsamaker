# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

require 'nokogiri'

module Glsamaker
  # Helper functions for Portage tree interaction
  module Portage
    
    # Package description helper
    class Description
      class << self
        # Tries to fetch the description for the package +atom+ from
        # an ebuild's entry (works if running on Gentoo)
        def ebuild(atom)
          return nil if GLSAMAKER_PORTDIR == false
          raise(ArgumentError, "Invalid package atom") unless Portage.valid_atom?(atom)

          dir = File.join(GLSAMAKER_PORTDIR, atom)
          
          nil
        end

        def eix(atom)
          nil
        end

        # Loads a description for +atom+ from packages.gentoo.org
        def pgo(atom)
          raise(ArgumentError, "Invalid package atom") unless valid_atom?(atom)

          n = Nokogiri::XML(Glsamaker::HTTP.get("http://packages.gentoo.org/package/#{atom}"))

          node = n.css('p.description').first.children.first
          if node.type == Nokogiri::XML::Node::TEXT_NODE
            node.to_s
          else
            raise ArgumentError, "XML parse error"
          end
        end

        # Loads a description for +atom+ from Google
        def google(atom)
          nil
        end
      end
    end
    
    module_function
    # Returns the location of the portage dir, or raises an exception if it cannot be found
    def portdir
      unless File.directory? GLSAMAKER_PORTDIR
        raise "GLSAMAKER_PORTDIR is not a directory"
      end
      
      GLSAMAKER_PORTDIR
    end
    
    # Validates the atom +atom+
    def valid_atom?(atom)
      atom =~ /[a-zA-Z0-9_-]\/[a-zA-Z0-9_-]/
    end    
    
    # Gets a description
    def get_description(atom)
      Description.eix(atom) ||
      Description.ebuild(atom) ||
      Description.pgo(atom) ||
      Description.google(atom) ||
      "[could not get a description]"
    end
  end
end