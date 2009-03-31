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

require 'net/http'

# GLSAMaker library
module Glsamaker
  # GLSAMaker HTTP utilities
  module HTTP
    # Tries to fetch +url+ via HTTP GET, sending a GLSAMaker custom User-Agent header.
    # The body part is returned.
    def get(url)
      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri.request_uri, {'User-Agent' => "GLSAMaker/#{GLSAMAKER_VERSION} (http://security.gentoo.org/)"})
      res = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
      
      # Raises an exception if HTTP status is not a successful one
      res.value
      res.body
    end
    
    module_function :get
  end
end