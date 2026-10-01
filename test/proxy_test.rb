# frozen_string_literal: true

require_relative 'test_helper'

class ProxyTest < Minitest::Test
  def test_parse_keeps_at_and_colon_in_password
    line = 'user-country-us:p@ss:w0rd@gw.buyproxy.org:6969'
    p = BuyProxy::Proxy.parse(line)
    assert_equal ['gw.buyproxy.org', 6969, 'user-country-us', 'p@ss:w0rd'], [p.host, p.port, p.username, p.password]
    assert_equal line, p.to_s
  end

  def test_url_percent_encodes_credentials
    assert_equal 'http://u:p%40ss@h.example:80', BuyProxy::Proxy.parse('u:p@ss@h.example:80').url
    assert_equal 'socks5://h.example:1080', BuyProxy::Proxy.parse('u:p@h.example:1080', 'socks5').server
  end

  def test_helpers
    p = BuyProxy::Proxy.parse('u:p@h.example:8080')
    assert_equal({ uri: 'http://h.example:8080', user: 'u', password: 'p' }, p.to_faraday)
    assert_equal ['h.example', 8080, 'u', 'p'], p.to_net_http
    assert_equal 'http://u:p@h.example:8080', p.env['HTTPS_PROXY']
  end

  ['', 'nope', 'u:p@host', 'u:p@host:99999', ':p@host:80', 'u@host:80'].each_with_index do |bad, i|
    define_method("test_rejects_malformed_#{i}") do
      assert_raises(ArgumentError) { BuyProxy::Proxy.parse(bad) }
    end
  end

  def test_generated_proxies_is_enumerable
    g = BuyProxy::GeneratedProxies.new(['a:b@h:1', 'c:d@h:2'])
    assert_equal 2, g.size
    assert_equal [1, 2], g.map(&:port)
  end
end
