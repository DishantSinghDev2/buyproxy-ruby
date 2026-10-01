# frozen_string_literal: true

module BuyProxy
  # Base class for every error raised by the SDK.
  class Error < StandardError
    # HTTP status, or nil for errors that never reached the API (network, timeout).
    attr_reader :status
    # Parsed JSON error body, when the API sent one.
    attr_reader :body

    def initialize(message = nil, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end

    def to_s
      status ? "#{super} (HTTP #{status})" : super
    end

    def self.from_response(status, body, retry_after = nil)
      message = body.is_a?(Hash) && body['error'].is_a?(String) ? body['error'] : 'BuyProxy API error'
      case status
      when 400 then ValidationError.new(message, status: status, body: body)
      when 401 then AuthenticationError.new(message, status: status, body: body)
      when 402 then InsufficientBandwidthError.new(message, status: status, body: body)
      when 403 then PermissionDeniedError.new(message, status: status, body: body)
      when 404 then NotFoundError.new(message, status: status, body: body)
      when 429 then RateLimitError.new(message, status: status, body: body, retry_after: retry_after)
      when 500.. then ServerError.new(message, status: status, body: body)
      else new(message, status: status, body: body)
      end
    end
  end

  # 400 — a parameter was missing or invalid.
  class ValidationError < Error; end
  # 401 — the API key is missing or invalid.
  class AuthenticationError < Error; end
  # 402 — empty reseller pool, or a plan with no GB left.
  class InsufficientBandwidthError < Error; end
  # 403 — suspended account or customer, or the plan doesn't include this endpoint.
  class PermissionDeniedError < Error; end
  # 404 — the plan, customer or transaction doesn't exist on this account.
  class NotFoundError < Error; end
  # 5xx — BuyProxy or an upstream provider is unavailable; usually safe to retry.
  class ServerError < Error; end
  # The request never got a response (DNS, reset, offline).
  class ConnectionError < Error; end
  # The request exceeded the configured timeout.
  class TimeoutError < ConnectionError; end

  # 429 — more than 60 requests/minute on this key.
  class RateLimitError < Error
    # Seconds the API asked you to wait, when it said.
    attr_reader :retry_after

    def initialize(message = nil, retry_after: nil, **kwargs)
      super(message, **kwargs)
      @retry_after = retry_after
    end
  end
end
