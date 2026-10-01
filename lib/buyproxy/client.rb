# frozen_string_literal: true

require 'json'
require 'uri'

module BuyProxy
  DEFAULT_BASE_URL = 'https://www.buyproxy.org'

  # BuyProxy API client.
  #
  #   bp = BuyProxy::Client.new(api_key: ENV['BUYPROXY_API_KEY'])
  #   result = bp.plans.generate(plan_id, country: 'US', count: 5)
  #   Faraday.new(proxy: result.first.to_faraday)
  class Client
    attr_reader :api_key, :products, :auth, :account, :balances, :plans, :topup, :transactions, :reseller

    def initialize(api_key: nil, base_url: DEFAULT_BASE_URL, timeout: 30, max_retries: 2, transport: nil)
      key = api_key.nil? ? ENV.fetch('BUYPROXY_API_KEY', nil) : api_key
      @api_key = key.nil? || key.empty? ? nil : key
      @base_url = base_url.sub(%r{/+\z}, '')
      @timeout = timeout
      @max_retries = max_retries
      @transport = transport || NetHttpTransport.new

      @products = Resources::Products.new(self)
      @auth = Resources::Auth.new(self)
      @account = Resources::Account.new(self)
      @balances = Resources::Balances.new(self)
      @plans = Resources::Plans.new(self)
      @topup = Resources::Topup.new(self)
      @transactions = Resources::Transactions.new(self)
      @reseller = Resources::Reseller.new(self)
    end

    # 'reseller' for bp_live_ keys, 'personal' for bp_key_ keys, nil without a key.
    def key_kind
      return nil unless @api_key

      @api_key.start_with?('bp_live_') ? 'reseller' : 'personal'
    end

    # @api private
    def request(method, path, query: {}, body: nil, headers: {}, public: false, retry_5xx: false)
      if !public && @api_key.nil?
        raise AuthenticationError.new('No API key — pass api_key: to the client or set BUYPROXY_API_KEY. ' \
                                      'Create one at https://www.buyproxy.org/dashboard/api-keys', status: 401)
      end

      query = query.compact
      uri = URI("#{@base_url}#{path}#{query.empty? ? '' : "?#{URI.encode_www_form(query)}"}")
      request_headers = { 'Accept' => 'application/json', 'User-Agent' => "buyproxy-ruby/#{VERSION}" }.merge(headers)
      request_headers['X-API-Key'] = @api_key if @api_key
      payload = nil
      unless body.nil?
        request_headers['Content-Type'] = 'application/json'
        payload = JSON.generate(body)
      end

      attempt = 0
      loop do
        begin
          status, response_headers, text = @transport.call(method, uri, request_headers, payload, @timeout)
        rescue ConnectionError
          raise unless retry_5xx && attempt < @max_retries

          sleep(backoff(attempt))
          attempt += 1
          next
        end

        parsed = text.nil? || text.empty? ? nil : safe_json(text)
        return success(status, text, parsed) if (200..299).cover?(status)

        retry_after = parse_retry_after(response_headers['retry-after'])
        wait = nil
        if attempt < @max_retries
          if status == 429
            wait = retry_after || backoff(attempt)
          elsif retry_5xx && [502, 503, 504].include?(status)
            wait = backoff(attempt)
          end
        end
        if wait
          sleep(wait)
          attempt += 1
          next
        end

        raise Error.from_response(status, parsed, retry_after)
      end
    end

    private

    def success(status, text, parsed)
      raise Error.new("BuyProxy returned a non-JSON response (HTTP #{status})", status: status) if parsed.nil? && text && !text.empty?

      parsed
    end

    def safe_json(text)
      JSON.parse(text)
    rescue JSON::ParserError
      nil
    end

    def parse_retry_after(value)
      seconds = Float(value, exception: false)
      seconds && seconds >= 0 ? [seconds, 30.0].min : nil
    end

    def backoff(attempt)
      [0.5 * (2**attempt), 8.0].min * (0.75 + (rand * 0.5))
    end
  end
end
