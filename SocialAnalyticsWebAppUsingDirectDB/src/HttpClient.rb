# Loading Ruby gems.
require 'rest_client'

# A class whose object is intended to encapsulate a HTTP response.
class HttpResponse
	def initialize(httpStatusCode = nil, cookies = nil, httpHeaders = nil, payload = nil)
		@httpStatusCode = httpStatusCode
		@cookies = cookies
		@httpHeaders = httpHeaders
		@payload = payload
	end

	def get_http_status_code
		return @httpStatusCode
	end

	def get_cookies
		return @cookies
	end

	def get_http_headers
		return @httpHeaders
	end

	def get_payload
		return @payload
	end
end

# A HTTP client to invoke URL's using specific HTTP methods.
module HttpClient
	# Makes a HTTP GET request to the given URL.
	def HttpClient.get(url, httpHeaders = nil)
		response = RestClient.get(url, httpHeaders) {|response, request, result|
			# Don't raise exceptions, just return back the response.
			response
		}

		return HttpClient._build_web_response(response)
	end

	# Makes a HTTP DELETE request to the given URL.
	def HttpClient.delete(url, httpHeaders = nil)
		response = RestClient.delete(url, httpHeaders) {|response, request, result|
			# Don't raise exceptions, just return back the response.
			response
		}

		return HttpClient._build_web_response(response)
	end

	# Makes a HTTP POST request to the given URL.
	def HttpClient.post(url, payload = nil, httpHeaders = nil)
		response = RestClient.post(url, payload, httpHeaders) {|response, request, result|
			# Don't raise exceptions, just return back the response.
			response
		}

		return HttpClient._build_web_response(response)
	end

	# Makes a HTTP PUT request to the given URL.
	def HttpClient.put(url, payload = nil, httpHeaders = nil)
		response = RestClient.put(url, payload, httpHeaders) {|response, request, result|
			# Don't raise exceptions, just return back the response.
			response
		}

		return HttpClient._build_web_response(response)
	end

	# An internal method that constructs a HTTP response.
	def HttpClient._build_web_response(response)
		return HttpResponse.new(response.code, response.cookies, response.headers, response.to_str)
	end
end