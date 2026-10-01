# frozen_string_literal: true

require_relative 'buyproxy/version'
require_relative 'buyproxy/errors'
require_relative 'buyproxy/proxy'
require_relative 'buyproxy/models'
require_relative 'buyproxy/http'
require_relative 'buyproxy/resources'
require_relative 'buyproxy/client'

# Official BuyProxy SDK — residential, mobile, ISP and datacenter proxies.
module BuyProxy
  # Shortcut: BuyProxy.new(api_key: '…') is BuyProxy::Client.new(api_key: '…').
  def self.new(**options)
    Client.new(**options)
  end
end
