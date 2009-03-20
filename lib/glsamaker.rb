require 'net/http'

module Glsamaker
  module HTTP
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