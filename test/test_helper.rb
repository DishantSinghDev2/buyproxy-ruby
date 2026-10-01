# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'buyproxy'
require 'minitest/autorun'

# Replays queued responses and records every request.
class FakeTransport
  attr_reader :requests

  def initialize(*queue)
    @queue = queue
    @requests = []
  end

  def self.json(status, body, headers = {})
    [status, headers, JSON.generate(body)]
  end

  def call(method, uri, headers, body, _timeout)
    @requests << { method: method, url: uri.to_s, headers: headers, body: body }
    nxt = @queue.shift or raise 'no more queued responses'
    raise nxt if nxt.is_a?(Exception)

    nxt
  end
end
