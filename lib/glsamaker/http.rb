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

require 'net/http'
require 'net/https'

# GLSAMaker library
module Glsamaker
  # GLSAMaker HTTP utilities
  module HTTP
    # Tries to fetch +url+ via HTTP GET, sending a GLSAMaker custom User-Agent header.
    # The body part is returned.
    def get(url)
      uri = URI.parse(url)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      res = http.start {
        http.request_get(uri.request_uri, {'User-Agent' => "GLSAMaker/#{GLSAMAKER_VERSION} (https://security.gentoo.org/)"})
      }
            
      # Raises an exception if HTTP status suggests something went wrong
      res.value
      res.body
    end
    
    module_function :get
  end
end
