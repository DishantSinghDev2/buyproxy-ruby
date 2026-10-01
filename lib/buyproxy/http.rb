# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'uri'

module BuyProxy
  # Default transport. Anything responding to `call(method, uri, headers, body, timeout)` and
  # returning `[status, headers_hash_with_lowercase_keys, body_string]` can replace it.
  class NetHttpTransport
    def call(method, uri, headers, body, timeout)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = [timeout, 10].min
      http.read_timeout = timeout
      request = Net::HTTP.const_get(method.capitalize).new(uri.request_uri, headers)
      request.body = body if body
      response = http.request(request)
      [response.code.to_i, response.each_header.to_h { |k, v| [k.downcase, v] }, response.body.to_s]
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise TimeoutError, "Request timed out after #{timeout}s (#{e.class})"
    rescue SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError, IOError => e
      raise ConnectionError, "Could not reach BuyProxy: #{e.message}"
    end
  end
end
