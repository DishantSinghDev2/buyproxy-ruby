# frozen_string_literal: true

require 'cgi'

module BuyProxy
  # One generated proxy. The API returns `username:password@host:port` lines.
  class Proxy
    attr_reader :host, :port, :username, :password, :protocol

    def initialize(host:, port:, username:, password:, protocol: 'http')
      @host = host
      @port = port
      @username = username
      @password = password
      @protocol = protocol
    end

    # Parse a `username:password@host:port` line ('@' and ':' are allowed inside the password).
    def self.parse(line, protocol = 'http')
      bad = ArgumentError.new("Not a proxy line (expected username:password@host:port): #{line.inspect}")
      at = line.rindex('@') or raise bad
      credentials = line[0...at]
      address = line[(at + 1)..]
      colon = credentials.index(':')
      last_colon = address.rindex(':')
      raise bad if colon.nil? || colon < 1 || last_colon.nil? || last_colon < 1

      port_text = address[(last_colon + 1)..]
      raise bad unless port_text.match?(/\A\d+\z/) && (1..65_535).cover?(port_text.to_i)

      new(host: address[0...last_colon], port: port_text.to_i, username: credentials[0...colon],
          password: credentials[(colon + 1)..], protocol: protocol)
    end

    # `username:password@host:port` — the form the API uses.
    def to_s
      "#{username}:#{password}@#{host}:#{port}"
    end

    # `http://host:port` — no credentials.
    def server
      "#{protocol}://#{host}:#{port}"
    end

    # Full URL with percent-encoded credentials, ready for any HTTP client.
    def url
      "#{protocol}://#{enc(username)}:#{enc(password)}@#{host}:#{port}"
    end

    # Faraday: `Faraday.new(proxy: proxy.to_faraday)`; HTTParty: `HTTParty.get(url, http_proxyaddr: ...)` — see to_httparty.
    def to_faraday
      { uri: server, user: username, password: password }
    end

    # HTTParty: `HTTParty.get(url, **proxy.to_httparty)`.
    def to_httparty
      { http_proxyaddr: host, http_proxyport: port, http_proxyuser: username, http_proxypass: password }
    end

    # Net::HTTP: `Net::HTTP.new(uri.host, uri.port, *proxy.to_net_http)`.
    def to_net_http
      [host, port, username, password]
    end

    # Selenium / Ferrum / Playwright-style hash.
    def to_playwright
      { server: server, username: username, password: password }
    end

    # Environment variables understood by curl, wget, git and most CLIs.
    def env
      %w[HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy].to_h { |k| [k, url] }
    end

    private

    def enc(value)
      CGI.escape(value.to_s).gsub('+', '%20')
    end
  end

  # The result of a generate call: raw lines plus parsed proxies.
  class GeneratedProxies
    include Enumerable

    attr_reader :lines, :proxies

    def initialize(lines, protocol = 'http')
      @lines = lines
      @proxies = lines.map { |l| Proxy.parse(l, protocol) }
    end

    def each(&block)
      proxies.each(&block)
    end

    def size
      proxies.size
    end
    alias length size

    def [](index)
      proxies[index]
    end
  end
end
